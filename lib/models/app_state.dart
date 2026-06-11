import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';

import 'package:soundpax/models/pad_state.dart';
import 'package:soundpax/src/rust/api/audio_types.dart' as rust_types;
import 'package:soundpax/src/rust/api/file_io.dart' as rust_file;
import 'package:soundpax/src/rust/api/audio_processor.dart' as rust_processor;
import 'package:soundpax/src/rust/api/bank_manager.dart' as rust_bank;
import 'package:soundpax/services/sound_export.dart';

enum RecordStatus { idle, recording, preview }

class AppState extends ChangeNotifier {
  late Directory _appDocDir;
  late Directory _soundsDir;
  late Directory _banksDir;

  bool _initialized = false;
  bool get initialized => _initialized;

  // Active Bank
  late BankState currentBank;
  List<rust_types.BankMeta> savedBanks = [];

  // Recorder states
  final AudioRecorder _recorder = AudioRecorder();
  RecordStatus recordStatus = RecordStatus.idle;
  String? tempRecordPath;
  int recordDurationSeconds = 0;
  Timer? _recordTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  /// Live mic levels during capture (0.0–1.0), newest at end.
  List<double> recordLevelHistory = [];
  /// RMS waveform of last take, for preview UI.
  List<double>? previewWaveform;
  int? activeRecordingTargetPad; // The pad index we are recording for, if any
  int? selectedPadIndex;
  bool showOnboarding = false;
  bool keepScreenOn = false;

  static const int _maxRecordLevelPoints = 96;

  /// Inspector color presets (session UI; not persisted in bank JSON yet).
  static const List<Color> padColorPresets = [
    Color(0xFF00E5FF),
    Color(0xFFB388FF),
    Color(0xFFFF6B9D),
    Color(0xFF00E676),
    Color(0xFFFFB74D),
    Color(0xFF1A2830),
    Color(0xFF28251C),
    Color(0xFF1C1C28),
  ];

  // Playback engine - pool of players for 16 pads
  final List<AudioPlayer?> _players = List.filled(16, null);
  AudioPlayer? _previewPlayer;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    // 1. Resolve directories
    _appDocDir = await getApplicationDocumentsDirectory();
    _soundsDir = Directory('${_appDocDir.path}/sounds');
    _banksDir = Directory('${_appDocDir.path}/banks');

    if (!await _soundsDir.exists()) await _soundsDir.create(recursive: true);
    if (!await _banksDir.exists()) await _banksDir.create(recursive: true);

    // 2. Initialize player pool
    for (int i = 0; i < 16; i++) {
      _players[i] = AudioPlayer();
    }
    _previewPlayer = AudioPlayer();

    // 3. Load or create default bank
    await refreshBanks();
    if (savedBanks.isEmpty) {
      // Create a default bank
      try {
        final rustBankObj = rust_bank.createDefaultBank(
          name: 'Default Bank',
          dirPath: _banksDir.path,
        );
        currentBank = BankState.fromRust(rustBankObj);
      } catch (e) {
        debugPrint('Failed to create default bank: $e');
        _createFallbackBank();
      }
    } else {
      await loadBank(savedBanks.first.path);
    }

    await _loadOnboardingFlag();

    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadOnboardingFlag() async {
    final flag = File('${_appDocDir.path}/onboarding_done.flag');
    showOnboarding = !await flag.exists();
  }

  Future<void> dismissOnboarding() async {
    await File('${_appDocDir.path}/onboarding_done.flag').writeAsString('1');
    showOnboarding = false;
    notifyListeners();
  }

  Future<void> toggleKeepScreenOn() async {
    keepScreenOn = !keepScreenOn;
    if (keepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    notifyListeners();
  }

  static Color defaultPadColor(int index) {
    const defaultColors = [
      Color(0xFF1C1C28),
      Color(0xFF231C28),
      Color(0xFF1C2825),
      Color(0xFF28251C),
    ];
    return defaultColors[index % defaultColors.length];
  }

  void _createFallbackBank() {
    final pads = List<PadState>.generate(16, (i) {
      return PadState(
        index: i,
        label: 'Pad ${i + 1}',
        padColor: defaultPadColor(i),
      );
    });
    currentBank = BankState(name: 'Default Bank', path: '', pads: pads);
  }

  // --- Bank Operations ---

  Future<void> refreshBanks() async {
    try {
      savedBanks = rust_bank.listBanks(dirPath: _banksDir.path);
    } catch (e) {
      debugPrint('Failed to list banks: $e');
    }
  }

  Future<void> loadBank(String path) async {
    try {
      final rustBankObj = rust_bank.loadBank(path: path);
      currentBank = BankState.fromRust(rustBankObj);
      
      // Update the player pool with the new sound files
      for (int i = 0; i < 16; i++) {
        final path = currentBank.pads[i].soundPath;
        if (path != null && await File(path).exists()) {
          await _players[i]?.setFilePath(path);
          // Set volume and loop
          await _players[i]?.setVolume(currentBank.pads[i].volume);
          await _players[i]?.setLoopMode(
            currentBank.pads[i].loopEnabled ? LoopMode.one : LoopMode.off,
          );
        } else {
          // Clear player file
          // just_audio doesn't have a direct clear/reset method without stopping,
          // but we will simply not play if soundPath is null.
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load bank: $e');
    }
  }

  Future<void> saveCurrentBank() async {
    try {
      currentBank.path = '${_banksDir.path}/${currentBank.name}.json';
      rust_bank.saveBank(
        bank: currentBank.toRust(),
        dirPath: _banksDir.path,
      );
      await refreshBanks();
    } catch (e) {
      debugPrint('Failed to save bank: $e');
    }
  }

  Future<void> createNewBank(String name) async {
    try {
      final rustBankObj = rust_bank.createDefaultBank(
        name: name,
        dirPath: _banksDir.path,
      );
      currentBank = BankState.fromRust(rustBankObj);
      await refreshBanks();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to create new bank: $e');
    }
  }

  Future<void> deleteBank(String path) async {
    try {
      rust_bank.deleteBank(path: path);
      await refreshBanks();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete bank: $e');
    }
  }

  // --- Playback Pad Actions ---

  void selectPad(int index) {
    selectedPadIndex = index;
    notifyListeners();
  }

  void renamePad(int index, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    currentBank.pads[index].label = trimmed;
    saveCurrentBank();
    notifyListeners();
  }

  Future<void> triggerPad(int index) async {
    selectPad(index);
    HapticFeedback.lightImpact();
    final pad = currentBank.pads[index];
    if (pad.soundPath == null) {
      // Trigger recording for this pad
      startRecordingPanel(targetPadIndex: index);
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      // Toggle play state visually
      pad.isPlaying = true;
      notifyListeners();

      // Trigger player
      final player = _players[index];
      if (player != null) {
        if (player.playing) {
          await player.seek(Duration.zero);
        } else {
          await player.setFilePath(pad.soundPath!);
          await player.setVolume(pad.volume);
          await player.setLoopMode(pad.loopEnabled ? LoopMode.one : LoopMode.off);
          
          // Listen to playback completion to reset visual state
          StreamSubscription<PlayerState>? sub;
          sub = player.playerStateStream.listen((state) {
            if (state.processingState == ProcessingState.completed) {
              pad.isPlaying = false;
              notifyListeners();
              sub?.cancel();
            }
          });
          
          await player.play();
        }
      }
    } catch (e) {
      debugPrint('Error playing sound on pad $index: $e');
      pad.isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopPad(int index) async {
    final pad = currentBank.pads[index];
    pad.isPlaying = false;
    await _players[index]?.stop();
    notifyListeners();
  }

  Future<void> stopAll() async {
    for (int i = 0; i < 16; i++) {
      currentBank.pads[i].isPlaying = false;
      await _players[i]?.stop();
    }
    notifyListeners();
  }

  /// Double-tap Stop: kill all pads, preview, and in-progress recording UI.
  Future<void> panicStop() async {
    await stopAll();
    await stopPreview();
    if (activeRecordingTargetPad != null) {
      await discardRecording();
      closeRecordingPanel();
    }
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void updatePadColor(int index, Color color) {
    currentBank.pads[index].padColor = color;
    notifyListeners();
  }

  Future<String?> renormalizePad(int index) async {
    final pad = currentBank.pads[index];
    final path = pad.soundPath;
    if (path == null) return 'Pad has no sound';

    try {
      final wavData = rust_file.loadWav(path: path);
      final normalized = rust_processor.normalizeSamples(
        samples: wavData.samples.map((s) => s.toDouble()).toList(),
      );
      rust_file.saveWav(
        path: path,
        samples: normalized.map((s) => s.toDouble()).toList(),
        sampleRate: wavData.sampleRate,
        channels: wavData.channels,
      );
      await _players[index]?.setFilePath(path);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Renormalize failed for pad $index: $e');
      return 'Normalize failed: $e';
    }
  }

  void updatePadVolume(int index, double vol) {
    currentBank.pads[index].volume = vol;
    _players[index]?.setVolume(vol);
    saveCurrentBank();
    notifyListeners();
  }

  void updatePadLoop(int index, bool loop) {
    currentBank.pads[index].loopEnabled = loop;
    _players[index]?.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    saveCurrentBank();
    notifyListeners();
  }

  Future<void> clearPad(int index) async {
    final pad = currentBank.pads[index];
    pad.soundPath = null;
    pad.label = 'Pad ${index + 1}';
    pad.padColor = defaultPadColor(index);
    pad.isPlaying = false;
    pad.loopEnabled = false;
    selectedPadIndex = index;
    await _players[index]?.stop();
    notifyListeners();
    await saveCurrentBank();
  }

  /// Share a single pad's WAV via the system share sheet.
  Future<String?> sharePadSound(int index) async {
    final pad = currentBank.pads[index];
    final path = pad.soundPath;
    if (path == null) return 'Pad has no sound';

    return SoundExport.shareWavs(
      files: [(path: path, name: pad.label)],
      subject: pad.label,
    );
  }

  /// Share every loaded pad in the current bank.
  Future<String?> shareCurrentBankSounds() async {
    final files = <({String path, String name})>[];
    for (final pad in currentBank.pads) {
      final path = pad.soundPath;
      if (path != null) {
        files.add((path: path, name: pad.label));
      }
    }

    return SoundExport.shareWavs(
      files: files,
      subject: '${currentBank.name} — SoundPax',
    );
  }

  // --- Sound Recording & Processing ---

  void startRecordingPanel({int? targetPadIndex}) {
    activeRecordingTargetPad = targetPadIndex;
    if (targetPadIndex != null) {
      selectedPadIndex = targetPadIndex;
    }
    recordStatus = RecordStatus.idle;
    recordDurationSeconds = 0;
    _clearRecordingVisuals();
    notifyListeners();
  }

  void closeRecordingPanel() {
    activeRecordingTargetPad = null;
    recordStatus = RecordStatus.idle;
    _clearRecordingVisuals();
    notifyListeners();
  }

  void _clearRecordingVisuals() {
    recordLevelHistory = [];
    previewWaveform = null;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
  }

  double _dbToLevel(double db) {
    // dBFS: silence ~-60, loud ~0
    return ((db.clamp(-60.0, 0.0) + 60.0) / 60.0).clamp(0.0, 1.0);
  }

  void _startAmplitudeMonitor() {
    _amplitudeSub?.cancel();
    recordLevelHistory = [];
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
      final level = _dbToLevel(amp.current);
      recordLevelHistory = [
        ...recordLevelHistory,
        level,
      ];
      if (recordLevelHistory.length > _maxRecordLevelPoints) {
        recordLevelHistory = recordLevelHistory.sublist(
          recordLevelHistory.length - _maxRecordLevelPoints,
        );
      }
      notifyListeners();
    });
  }

  Future<void> _loadPreviewWaveform() async {
    if (tempRecordPath == null) return;
    try {
      final wavData = rust_file.loadWav(path: tempRecordPath!);
      final waveform = rust_processor.getWaveformData(
        samples: wavData.samples.map((s) => s.toDouble()).toList(),
        numPoints: _maxRecordLevelPoints,
      );
      previewWaveform = waveform.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load preview waveform: $e');
    }
  }

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      recordStatus = RecordStatus.recording;
      recordDurationSeconds = 0;
      previewWaveform = null;
      recordLevelHistory = [];
      tempRecordPath = '${_soundsDir.path}/temp_record.wav';

      // Start recording WAV format
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1),
        path: tempRecordPath!,
      );

      _startAmplitudeMonitor();

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordDurationSeconds++;
        notifyListeners();
      });

      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    _recordTimer?.cancel();
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _recorder.stop();
    recordStatus = RecordStatus.preview;
    notifyListeners();
    await _loadPreviewWaveform();
  }

  Future<void> playPreview() async {
    if (tempRecordPath != null && await File(tempRecordPath!).exists()) {
      await _previewPlayer?.setFilePath(tempRecordPath!);
      await _previewPlayer?.play();
    }
  }

  Future<void> stopPreview() async {
    await _previewPlayer?.stop();
  }

  Future<void> discardRecording() async {
    await stopPreview();
    if (tempRecordPath != null) {
      final f = File(tempRecordPath!);
      if (await f.exists()) {
        await f.delete();
      }
    }
    recordStatus = RecordStatus.idle;
    _clearRecordingVisuals();
    notifyListeners();
  }

  // Finalizes the recorded sound, processes it via Rust (normalizes), saves it, and assigns it to pad
  Future<void> saveAndAssignRecording(String customName) async {
    if (tempRecordPath == null || activeRecordingTargetPad == null) return;
    
    final finalFileName = '${customName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final finalPath = '${_soundsDir.path}/$finalFileName';

    try {
      // Load WAV via Rust
      final wavData = rust_file.loadWav(path: tempRecordPath!);

      // Peak normalize via Rust
      final normalizedSamples = rust_processor.normalizeSamples(
        samples: wavData.samples.map((s) => s.toDouble()).toList(),
      );

      // Save the processed WAV file via Rust
      rust_file.saveWav(
        path: finalPath,
        samples: normalizedSamples.map((s) => s.toDouble()).toList(),
        sampleRate: wavData.sampleRate,
        channels: wavData.channels,
      );

      // Clean up temp record file
      final tempFile = File(tempRecordPath!);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Assign to the selected target pad
      final pad = currentBank.pads[activeRecordingTargetPad!];
      pad.soundPath = finalPath;
      pad.label = customName;
      pad.padColor = const Color(0xFF00E5FF); // Accent Cyan for loaded pad

      // Load sound into player
      await _players[activeRecordingTargetPad!]?.setFilePath(finalPath);
      await _players[activeRecordingTargetPad!]?.setVolume(pad.volume);
      await _players[activeRecordingTargetPad!]?.setLoopMode(
        pad.loopEnabled ? LoopMode.one : LoopMode.off,
      );

      // Save current bank state
      await saveCurrentBank();

      // Reset recorder status
      recordStatus = RecordStatus.idle;
      activeRecordingTargetPad = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to normalize or save WAV: $e');
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _amplitudeSub?.cancel();
    if (keepScreenOn) {
      WakelockPlus.disable();
    }
    _recorder.dispose();
    _previewPlayer?.dispose();
    for (var p in _players) {
      p?.dispose();
    }
    super.dispose();
  }
}

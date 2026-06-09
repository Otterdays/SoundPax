import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
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
  int? activeRecordingTargetPad; // The pad index we are recording for, if any

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

    _initialized = true;
    notifyListeners();
  }

  void _createFallbackBank() {
    final defaultColors = [
      const Color(0xFF1C1C28),
      const Color(0xFF231C28),
      const Color(0xFF1C2825),
      const Color(0xFF28251C),
    ];
    final pads = List<PadState>.generate(16, (i) {
      return PadState(
        index: i,
        label: 'Pad ${i + 1}',
        padColor: defaultColors[i % defaultColors.length],
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

  Future<void> triggerPad(int index) async {
    final pad = currentBank.pads[index];
    if (pad.soundPath == null) {
      // Trigger recording for this pad
      startRecordingPanel(targetPadIndex: index);
      return;
    }

    try {
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

  void clearPad(int index) {
    currentBank.pads[index].soundPath = null;
    currentBank.pads[index].label = 'Pad ${index + 1}';
    currentBank.pads[index].padColor = const Color(0xFF1E1E1E);
    _players[index]?.stop();
    saveCurrentBank();
    notifyListeners();
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
    recordStatus = RecordStatus.idle;
    recordDurationSeconds = 0;
    notifyListeners();
  }

  void closeRecordingPanel() {
    activeRecordingTargetPad = null;
    recordStatus = RecordStatus.idle;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      recordStatus = RecordStatus.recording;
      recordDurationSeconds = 0;
      tempRecordPath = '${_soundsDir.path}/temp_record.wav';

      // Start recording WAV format
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1),
        path: tempRecordPath!,
      );

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordDurationSeconds++;
        notifyListeners();
      });

      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    recordStatus = RecordStatus.preview;
    notifyListeners();
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
    _recorder.dispose();
    _previewPlayer?.dispose();
    for (var p in _players) {
      p?.dispose();
    }
    super.dispose();
  }
}

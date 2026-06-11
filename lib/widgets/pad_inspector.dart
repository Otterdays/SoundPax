import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/models/pad_state.dart';
import 'package:soundpax/src/rust/api/audio_processor.dart' as rust_processor;
import 'package:soundpax/src/rust/api/file_io.dart' as rust_file;
import 'package:soundpax/theme/app_theme.dart';
import 'package:soundpax/widgets/waveform_display.dart';

class PadInspector extends StatefulWidget {
  const PadInspector({super.key});

  @override
  State<PadInspector> createState() => _PadInspectorState();
}

class _PadInspectorState extends State<PadInspector> {
  final _nameController = TextEditingController();
  int? _editingPadIndex;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncNameField(PadState pad, int index) {
    final label = pad.label;
    if (_editingPadIndex != index || _nameController.text != label) {
      _editingPadIndex = index;
      _nameController.text = label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final index = appState.selectedPadIndex;
    final pad = index != null ? appState.currentBank.pads[index] : null;
    final loadedCount = appState.currentBank.pads
        .where((p) => p.soundPath != null)
        .length;

    if (pad != null) {
      _syncNameField(pad, index!);
    } else {
      _editingPadIndex = null;
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        border: Border(
          left: BorderSide(color: AppTheme.surfaceBright, width: 0.5),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text(
            'Inspector',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.currentBank.name,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (pad == null)
            _EmptySelection(loadedCount: loadedCount)
          else if (pad.soundPath == null)
            _EmptyPadPanel(padIndex: index!, appState: appState)
          else
            _LoadedPadPanel(
              key: ValueKey('${index}_${pad.soundPath}'),
              pad: pad,
              padIndex: index!,
              appState: appState,
              nameController: _nameController,
            ),
        ],
      ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  final int loadedCount;

  const _EmptySelection({required this.loadedCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.touch_app_outlined,
          size: 48,
          color: AppTheme.textDim.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap a pad to select',
          style: TextStyle(
            color: AppTheme.textBright,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loadedCount == 0
              ? 'Empty pads open the recorder. Loaded pads play on tap.'
              : '$loadedCount / 16 pads loaded · Long-press for more options',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptyPadPanel extends StatelessWidget {
  final int padIndex;
  final AppState appState;

  const _EmptyPadPanel({
    required this.padIndex,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pad ${padIndex + 1}',
          style: const TextStyle(
            color: AppTheme.textBright,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'No sample assigned',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () =>
              appState.startRecordingPanel(targetPadIndex: padIndex),
          icon: const Icon(Icons.mic),
          label: const Text('Record sample'),
        ),
      ],
    );
  }
}

class _LoadedPadPanel extends StatefulWidget {
  final PadState pad;
  final int padIndex;
  final AppState appState;
  final TextEditingController nameController;

  const _LoadedPadPanel({
    super.key,
    required this.pad,
    required this.padIndex,
    required this.appState,
    required this.nameController,
  });

  @override
  State<_LoadedPadPanel> createState() => _LoadedPadPanelState();
}

class _LoadedPadPanelState extends State<_LoadedPadPanel> {
  List<double>? _waveform;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  Future<void> _loadWaveform() async {
    final path = widget.pad.soundPath;
    if (path == null) return;

    try {
      final wav = rust_file.loadWav(path: path);
      final data = rust_processor.getWaveformData(
        samples: wav.samples.map((s) => s.toDouble()).toList(),
        numPoints: 120,
      );
      if (mounted) setState(() => _waveform = data.toList());
    } catch (e) {
      debugPrint('PadInspector waveform load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.pad;
    final padIndex = widget.padIndex;
    final appState = widget.appState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: pad.padColor,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.primaryCyan),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pad ${padIndex + 1}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (pad.isPlaying) ...[
              const SizedBox(width: 8),
              const Icon(Icons.graphic_eq, size: 16, color: AppTheme.primaryCyan),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _PadColorPicker(
          selected: pad.padColor,
          onPick: (c) => appState.updatePadColor(padIndex, c),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.nameController,
          decoration: const InputDecoration(
            labelText: 'Sample name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => appState.renamePad(padIndex, v),
          onEditingComplete: () =>
              appState.renamePad(padIndex, widget.nameController.text),
        ),
        const SizedBox(height: 16),
        if (_waveform != null)
          StaticWaveformDisplay(
            samples: _waveform!,
            label: 'Waveform',
            height: 96,
          )
        else
          Container(
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryCyan,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Volume · ${(pad.volume * 100).round()}%',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        Slider(
          value: pad.volume,
          onChanged: (v) => appState.updatePadVolume(padIndex, v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Loop'),
          value: pad.loopEnabled,
          activeThumbColor: AppTheme.secondaryPurple,
          onChanged: (v) => appState.updatePadLoop(padIndex, v),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => appState.triggerPad(padIndex),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            OutlinedButton.icon(
              onPressed: () => appState.stopPad(padIndex),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final error = await appState.sharePadSound(padIndex);
                if (context.mounted && error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final error = await appState.renormalizePad(padIndex);
                if (!mounted) return;
                if (error != null) {
                  messenger.showSnackBar(SnackBar(content: Text(error)));
                } else {
                  setState(() => _waveform = null);
                  await _loadWaveform();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Sample re-normalized')),
                  );
                }
              },
              icon: const Icon(Icons.graphic_eq),
              label: const Text('Normalize'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text('Clear pad?'),
                    content: Text(
                      'Remove "${pad.label}" from pad ${padIndex + 1}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.alertRed,
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await appState.clearPad(padIndex);
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed),
              label: const Text(
                'Clear',
                style: TextStyle(color: AppTheme.alertRed),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;

  const _PadColorPicker({
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pad color',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppState.padColorPresets.map((color) {
            final isSelected = color.toARGB32() == selected.toARGB32();
            return InkWell(
              onTap: () => onPick(color),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.textBright
                        : AppTheme.surfaceBright,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

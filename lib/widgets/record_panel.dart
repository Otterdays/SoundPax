import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';

class RecordPanel extends StatefulWidget {
  const RecordPanel({super.key});

  @override
  State<RecordPanel> createState() => _RecordPanelState();
}

class _RecordPanelState extends State<RecordPanel>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController(text: 'Sample');
  late AnimationController _meterController;

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _meterController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final targetPad = appState.activeRecordingTargetPad;
    if (targetPad == null) return const SizedBox.shrink();

    final isRecording = appState.recordStatus == RecordStatus.recording;
    final isPreview = appState.recordStatus == RecordStatus.preview;

    return Material(
      color: const Color(0xFF121212),
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Record → Pad ${targetPad + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await appState.discardRecording();
                      appState.closeRecordingPanel();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isRecording)
                AnimatedBuilder(
                  animation: _meterController,
                  builder: (context, _) {
                    return _WaveformMeter(t: _meterController.value);
                  },
                )
              else
                Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPreview ? 'Preview your take' : 'Tap record to capture',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRecording)
                    Text(
                      _formatDuration(appState.recordDurationSeconds),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.alertRed,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRecording && !isPreview)
                    _ActionButton(
                      icon: Icons.fiber_manual_record,
                      label: 'Record',
                      color: AppTheme.alertRed,
                      onPressed: () => appState.startRecording(),
                    ),
                  if (isRecording)
                    _ActionButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      color: AppTheme.alertRed,
                      onPressed: () => appState.stopRecording(),
                    ),
                  if (isPreview) ...[
                    _ActionButton(
                      icon: Icons.play_arrow,
                      label: 'Preview',
                      color: AppTheme.primaryCyan,
                      onPressed: () => appState.playPreview(),
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      color: AppTheme.textMuted,
                      onPressed: () => appState.stopPreview(),
                    ),
                  ],
                ],
              ),
              if (isPreview) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sample name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => appState.discardRecording(),
                        child: const Text('Discard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          appState.saveAndAssignRecording(
                            name.isEmpty ? 'Sample' : name,
                          );
                        },
                        child: const Text('Save to pad'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          iconSize: 36,
          icon: Icon(icon),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(64, 64),
          ),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _WaveformMeter extends StatelessWidget {
  final double t;

  const _WaveformMeter({required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (i) {
          final phase = sin((i * 0.55) + (t * pi * 2));
          final height = 8.0 + ((phase + 1) / 2) * 36;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: height,
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(
                    alpha: 0.4 + (height / 48) * 0.6,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

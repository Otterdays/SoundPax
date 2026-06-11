import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';
import 'package:soundpax/widgets/waveform_display.dart';

const _waveformSlotCount = 96;

class RecordPanel extends StatefulWidget {
  const RecordPanel({super.key});

  @override
  State<RecordPanel> createState() => _RecordPanelState();
}

class _RecordPanelState extends State<RecordPanel> {
  final _nameController = TextEditingController(text: 'Sample');

  @override
  void dispose() {
    _nameController.dispose();
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
                _WaveformGraph(
                  samples: appState.recordLevelHistory,
                  live: true,
                  accent: AppTheme.alertRed,
                  label: 'Listening…',
                )
              else if (isPreview && appState.previewWaveform != null)
                StaticWaveformDisplay(
                  samples: appState.previewWaveform!,
                  label: 'Recorded waveform',
                  height: 72,
                )
              else
                Container(
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.surfaceBright.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    isPreview
                        ? 'Loading waveform…'
                        : 'Tap record to capture',
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

class _WaveformGraph extends StatelessWidget {
  final List<double> samples;
  final bool live;
  final Color accent;
  final String label;

  const _WaveformGraph({
    required this.samples,
    required this.live,
    required this.accent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (live)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.alertRed,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: live ? AppTheme.alertRed : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: live
                  ? AppTheme.alertRed.withValues(alpha: 0.35)
                  : AppTheme.primaryCyan.withValues(alpha: 0.35),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: CustomPaint(
            painter: _WaveformPainter(
              samples: samples,
              accent: accent,
              live: live,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color accent;
  final bool live;

  _WaveformPainter({
    required this.samples,
    required this.accent,
    required this.live,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final gridPaint = Paint()
      ..color = AppTheme.surfaceBright.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (samples.isEmpty) return;

    final count = samples.length;
    final slotWidth = size.width / (live ? _waveformSlotCount : count);

    for (var i = 0; i < count; i++) {
      final level = samples[i].clamp(0.0, 1.0);
      final barHeight = level * (size.height * 0.9);
      final x = live
          ? size.width - (count - i) * slotWidth + slotWidth / 2
          : i * slotWidth + slotWidth / 2;

      if (x < 0 || x > size.width) continue;

      final barPaint = Paint()
        ..color = accent.withValues(alpha: 0.35 + level * 0.65)
        ..strokeWidth = (slotWidth * 0.55).clamp(2.0, 6.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, midY - barHeight / 2),
        Offset(x, midY + barHeight / 2),
        barPaint,
      );
    }

    if (live && count > 1) {
      final path = Path();
      final startIndex =
          count > _waveformSlotCount ? count - _waveformSlotCount : 0;

      for (var i = startIndex; i < count; i++) {
        final level = samples[i].clamp(0.0, 1.0);
        final x = size.width - (count - i) * slotWidth + slotWidth / 2;
        final y = midY - level * (size.height * 0.35);

        if (i == startIndex) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final linePaint = Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.accent != accent ||
        oldDelegate.live != live;
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

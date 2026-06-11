import 'package:flutter/material.dart';
import 'package:soundpax/theme/app_theme.dart';

/// Static RMS waveform bars (record preview + pad inspector).
class StaticWaveformDisplay extends StatelessWidget {
  final List<double> samples;
  final String label;
  final double height;

  const StaticWaveformDisplay({
    super.key,
    required this.samples,
    required this.label,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryCyan.withValues(alpha: 0.35),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: CustomPaint(
            painter: _StaticWaveformPainter(samples: samples),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _StaticWaveformPainter extends CustomPainter {
  final List<double> samples;

  _StaticWaveformPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final gridPaint = Paint()
      ..color = AppTheme.surfaceBright.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (samples.isEmpty) return;

    final count = samples.length;
    final slotWidth = size.width / count;
    final maxSample = samples.reduce((a, b) => a > b ? a : b);
    final scale = maxSample > 0 ? 1.0 / maxSample : 1.0;

    for (var i = 0; i < count; i++) {
      final level = (samples[i] * scale).clamp(0.0, 1.0);
      final barHeight = level * (size.height * 0.9);
      final x = i * slotWidth + slotWidth / 2;

      final barPaint = Paint()
        ..color = AppTheme.primaryCyan.withValues(alpha: 0.35 + level * 0.65)
        ..strokeWidth = (slotWidth * 0.55).clamp(2.0, 6.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, midY - barHeight / 2),
        Offset(x, midY + barHeight / 2),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StaticWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}

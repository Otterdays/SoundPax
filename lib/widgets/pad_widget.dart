import 'dart:math';

import 'package:flutter/material.dart';
import 'package:soundpax/models/pad_state.dart';
import 'package:soundpax/theme/app_theme.dart';

class PadWidget extends StatefulWidget {
  final PadState pad;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PadWidget({
    super.key,
    required this.pad,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<PadWidget> createState() => _PadWidgetState();
}

class _PadWidgetState extends State<PadWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _syncWaveformAnimation();
  }

  @override
  void didUpdateWidget(PadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWaveformAnimation();
  }

  void _syncWaveformAnimation() {
    if (widget.pad.isPlaying) {
      if (!_waveformController.isAnimating) {
        _waveformController.repeat();
      }
    } else {
      _waveformController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.pad;
    final hasSound = pad.soundPath != null;
    final isActive = pad.isPlaying || pad.isRecordingTarget;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: pad.padColor,
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryCyan
                  : widget.isSelected
                      ? AppTheme.secondaryPurple
                      : hasSound
                          ? AppTheme.primaryCyan.withValues(alpha: 0.35)
                          : AppTheme.surfaceBright,
              width: isActive || widget.isSelected ? 2.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 88;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: compact ? 4 : 8,
                    left: compact ? 6 : 10,
                    child: Text(
                      '${pad.index + 1}',
                      style: TextStyle(
                        fontSize: compact ? 9 : 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDim.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        6,
                        compact ? 14 : 18,
                        6,
                        pad.loopEnabled ? (compact ? 14 : 18) : 6,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth - 12,
                            maxHeight: constraints.maxHeight - 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pad.isPlaying && hasSound) ...[
                                Text(
                                  pad.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compact ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textBright,
                                  ),
                                ),
                                SizedBox(height: compact ? 2 : 4),
                                Text(
                                  'PLAYING',
                                  style: TextStyle(
                                    fontSize: compact ? 7 : 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: AppTheme.primaryCyan
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                                SizedBox(height: compact ? 4 : 6),
                                _PadWaveform(
                                  t: _waveformController,
                                  barCount: compact ? 6 : 8,
                                  height: compact ? 14 : 22,
                                ),
                              ] else ...[
                                Icon(
                                  hasSound
                                      ? Icons.graphic_eq
                                      : Icons.mic_none,
                                  size: compact ? 20 : 28,
                                  color: hasSound
                                      ? AppTheme.textBright
                                      : AppTheme.textMuted,
                                ),
                                SizedBox(height: compact ? 3 : 6),
                                Text(
                                  pad.label,
                                  maxLines: compact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compact ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: hasSound
                                        ? AppTheme.textBright
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (pad.loopEnabled)
                    Positioned(
                      bottom: compact ? 4 : 6,
                      right: compact ? 4 : 8,
                      child: Icon(
                        Icons.loop,
                        size: compact ? 11 : 14,
                        color: AppTheme.secondaryPurple,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PadWaveform extends StatelessWidget {
  final Animation<double> t;
  final int barCount;
  final double height;

  const _PadWaveform({
    required this.t,
    required this.barCount,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        return SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final phase = sin((i * 0.7) + (t.value * pi * 2));
              final barHeight = 4.0 + ((phase + 1) / 2) * (height - 4);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 3,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(
                      alpha: 0.55 + (barHeight / height) * 0.45,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

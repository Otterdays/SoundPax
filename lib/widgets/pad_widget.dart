import 'package:flutter/material.dart';
import 'package:soundpax/models/pad_state.dart';
import 'package:soundpax/theme/app_theme.dart';

class PadWidget extends StatefulWidget {
  final PadState pad;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PadWidget({
    super.key,
    required this.pad,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<PadWidget> createState() => _PadWidgetState();
}

class _PadWidgetState extends State<PadWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(PadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pad.isPlaying && !oldWidget.pad.isPlaying) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: pad.isPlaying ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: pad.padColor,
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryCyan
                  : hasSound
                      ? AppTheme.primaryCyan.withValues(alpha: 0.35)
                      : AppTheme.surfaceBright,
              width: isActive ? 2.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 10,
                child: Text(
                  '${pad.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDim.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasSound ? Icons.graphic_eq : Icons.mic_none,
                        size: 28,
                        color: hasSound
                            ? AppTheme.textBright
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pad.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasSound
                              ? AppTheme.textBright
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pad.loopEnabled)
                const Positioned(
                  bottom: 6,
                  right: 8,
                  child: Icon(
                    Icons.loop,
                    size: 14,
                    color: AppTheme.secondaryPurple,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

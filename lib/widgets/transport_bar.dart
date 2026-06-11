import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/screens/bank_screen.dart';
import 'package:soundpax/theme/app_theme.dart';

class TransportBar extends StatelessWidget {
  const TransportBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBright, width: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Row(
            children: [
              Icon(
                Icons.grid_view,
                color: AppTheme.primaryCyan,
                size: compact ? 18 : 22,
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SoundPax',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 14 : 16,
                        color: AppTheme.textBright,
                      ),
                    ),
                    Text(
                      appState.initialized
                          ? appState.currentBank.name
                          : 'Loading…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _KeepAwakeToggle(compact: compact, enabled: appState.initialized),
              SizedBox(width: compact ? 4 : 8),
              _PanicStopButton(compact: compact, enabled: appState.initialized),
              SizedBox(width: compact ? 4 : 8),
              _TransportButton(
                icon: Icons.share,
                label: 'Share',
                compact: compact,
                onPressed: appState.initialized
                    ? () async {
                        final error = await appState.shareCurrentBankSounds();
                        if (context.mounted && error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }
                    : null,
              ),
              SizedBox(width: compact ? 4 : 8),
              _TransportButton(
                icon: Icons.folder_open,
                label: 'Banks',
                compact: compact,
                onPressed: appState.initialized
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BankScreen(),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KeepAwakeToggle extends StatelessWidget {
  final bool compact;
  final bool enabled;

  const _KeepAwakeToggle({
    required this.compact,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final on = appState.keepScreenOn;

    return Tooltip(
      message: on ? 'Keep awake on' : 'Keep screen on',
      child: InkWell(
        onTap: enabled ? () => appState.toggleKeepScreenOn() : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 4 : 6,
          ),
          child: Icon(
            on ? Icons.wb_sunny : Icons.bedtime_outlined,
            size: compact ? 20 : 22,
            color: on
                ? AppTheme.primaryCyan
                : enabled
                    ? AppTheme.textBright
                    : AppTheme.textDim,
          ),
        ),
      ),
    );
  }
}

class _PanicStopButton extends StatefulWidget {
  final bool compact;
  final bool enabled;

  const _PanicStopButton({
    required this.compact,
    required this.enabled,
  });

  @override
  State<_PanicStopButton> createState() => _PanicStopButtonState();
}

class _PanicStopButtonState extends State<_PanicStopButton> {
  DateTime? _lastTap;

  Future<void> _onTap() async {
    final appState = context.read<AppState>();
    final now = DateTime.now();
    final isDoubleTap = _lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 450);

    if (isDoubleTap) {
      _lastTap = null;
      await appState.panicStop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panic stop — all audio stopped'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _lastTap = now;
      await appState.stopAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap: stop pads · Double-tap: panic stop',
      child: InkWell(
        onTap: widget.enabled ? _onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 6 : 10,
            vertical: widget.compact ? 4 : 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stop_circle_outlined,
                size: widget.compact ? 20 : 22,
                color: widget.enabled
                    ? AppTheme.textBright
                    : AppTheme.textDim,
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 2),
                Text(
                  'Stop',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.enabled
                        ? AppTheme.textMuted
                        : AppTheme.textDim,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onPressed;

  const _TransportButton({
    required this.icon,
    required this.label,
    this.compact = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 20.0 : 22.0;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 4 : 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: onPressed != null
                  ? AppTheme.textBright
                  : AppTheme.textDim,
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: onPressed != null
                      ? AppTheme.textMuted
                      : AppTheme.textDim,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

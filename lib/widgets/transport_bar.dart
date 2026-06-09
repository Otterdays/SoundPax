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
      child: Row(
        children: [
          const Icon(Icons.grid_view, color: AppTheme.primaryCyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SoundPax',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textBright,
                  ),
                ),
                Text(
                  appState.initialized
                      ? appState.currentBank.name
                      : 'Loading…',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _TransportButton(
            icon: Icons.stop_circle_outlined,
            label: 'Stop',
            onPressed: appState.initialized ? () => appState.stopAll() : null,
          ),
          const SizedBox(width: 8),
          _TransportButton(
            icon: Icons.share,
            label: 'Share',
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
          const SizedBox(width: 8),
          _TransportButton(
            icon: Icons.folder_open,
            label: 'Banks',
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
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _TransportButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: onPressed != null
                  ? AppTheme.textBright
                  : AppTheme.textDim,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: onPressed != null
                    ? AppTheme.textMuted
                    : AppTheme.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

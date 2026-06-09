import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';
import 'package:soundpax/widgets/pad_grid.dart';
import 'package:soundpax/widgets/record_panel.dart';
import 'package:soundpax/widgets/transport_bar.dart';

class PadScreen extends StatelessWidget {
  const PadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TransportBar(),
            Expanded(
              child: appState.initialized
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: const PadGrid(),
                              ),
                            ),
                          ),
                          if (appState.activeRecordingTargetPad == null)
                            _HintBar(appState: appState),
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryCyan,
                      ),
                    ),
            ),
            if (appState.activeRecordingTargetPad != null)
              const RecordPanel(),
          ],
        ),
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  final AppState appState;

  const _HintBar({required this.appState});

  @override
  Widget build(BuildContext context) {
    final loadedCount = appState.currentBank.pads
        .where((p) => p.soundPath != null)
        .length;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        loadedCount == 0
            ? 'Tap an empty pad to record · Long-press for options'
            : '$loadedCount / 16 pads loaded · Tap to play · Long-press to edit or share',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
      ),
    );
  }
}

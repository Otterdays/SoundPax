import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';
import 'package:soundpax/widgets/pad_grid.dart';
import 'package:soundpax/widgets/pad_inspector.dart';
import 'package:soundpax/widgets/record_panel.dart';
import 'package:soundpax/widgets/onboarding_overlay.dart';
import 'package:soundpax/widgets/transport_bar.dart';

class PadScreen extends StatelessWidget {
  const PadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                const TransportBar(),
                Expanded(
                  child: appState.initialized
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(
                                flex: 5,
                                child: PadGrid(),
                              ),
                              const Expanded(
                                flex: 3,
                                child: PadInspector(),
                              ),
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
            if (appState.showOnboarding) const OnboardingOverlay(),
          ],
        ),
      ),
    );
  }
}

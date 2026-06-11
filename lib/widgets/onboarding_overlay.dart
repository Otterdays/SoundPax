import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';

class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  final _pageController = PageController();
  int _page = 0;

  static const _steps = [
    (
      icon: Icons.grid_view,
      title: '16-pad soundboard',
      body:
          'Tap an empty pad to record. Tap a loaded pad to play. Long-press for quick options.',
    ),
    (
      icon: Icons.tune,
      title: 'Inspector panel',
      body:
          'Rename samples, view waveforms, adjust volume and loop, and pick pad colors on the right.',
    ),
    (
      icon: Icons.landscape,
      title: 'Built for tablets',
      body:
          'Landscape-only layout with immersive mode. Double-tap Stop for panic mute. Toggle keep-awake in the bar.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Welcome to SoundPax',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textBright,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => appState.dismissOnboarding(),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        final step = _steps[i];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              step.icon,
                              size: 56,
                              color: AppTheme.primaryCyan,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textBright,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page
                              ? AppTheme.primaryCyan
                              : AppTheme.textDim,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                          child: const Text('Back'),
                        )
                      else
                        const Spacer(),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          if (_page < _steps.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          } else {
                            appState.dismissOnboarding();
                          }
                        },
                        child: Text(
                          _page < _steps.length - 1 ? 'Next' : 'Get started',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

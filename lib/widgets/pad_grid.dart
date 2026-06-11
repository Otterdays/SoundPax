import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';
import 'package:soundpax/widgets/pad_widget.dart';

class PadGrid extends StatelessWidget {
  const PadGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        const spacing = 10.0;
        const totalSpacing = spacing * (crossAxisCount - 1);

        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : constraints.maxHeight;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : maxWidth;

        final cellFromWidth = (maxWidth - totalSpacing) / crossAxisCount;
        final cellFromHeight = (maxHeight - totalSpacing) / crossAxisCount;
        final cellSize =
            min(cellFromWidth, cellFromHeight).floorToDouble().clamp(48.0, 240.0);
        final gridExtent = cellSize * crossAxisCount + totalSpacing;

        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: gridExtent,
            height: gridExtent,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: cellSize,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final pad = appState.currentBank.pads[index];
                pad.isRecordingTarget =
                    appState.activeRecordingTargetPad == index;

                return PadWidget(
                  key: ValueKey('pad-$index-${pad.soundPath ?? 'empty'}'),
                  pad: pad,
                  isSelected: appState.selectedPadIndex == index,
                  onTap: () => appState.triggerPad(index),
                  onLongPress: () => _showPadMenu(context, appState, index),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showPadMenu(BuildContext context, AppState appState, int index) {
    final pad = appState.currentBank.pads[index];
    final label = pad.label;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pad ${index + 1}',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (pad.soundPath != null) ...[
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text('Stop pad'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    appState.stopPad(index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.loop),
                  title: Text(pad.loopEnabled ? 'Disable loop' : 'Enable loop'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    appState.updatePadLoop(index, !pad.loopEnabled);
                  },
                ),
                Slider(
                  value: pad.volume,
                  onChanged: (v) => appState.updatePadVolume(index, v),
                  label: '${(pad.volume * 100).round()}%',
                ),
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text('Re-record'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    appState.startRecordingPanel(targetPadIndex: index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share sound'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final error = await appState.sharePadSound(index);
                    if (context.mounted && error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Clear pad'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text('Clear pad?'),
                        content: Text(
                          'Remove "$label" from pad ${index + 1}? '
                          'The sound file will stay on disk but the pad will be empty.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.alertRed,
                            ),
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await appState.clearPad(index);
                    }
                  },
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text('Record sound'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    appState.startRecordingPanel(targetPadIndex: index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/theme/app_theme.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createBank(BuildContext context) async {
    _nameController.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('New sound bank'),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Bank name',
              hintText: 'My Kit',
            ),
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, _nameController.text.trim());
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<AppState>().createNewBank(name);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState appState,
    String path,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete bank?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final isCurrent = appState.currentBank.path == path;
      await appState.deleteBank(path);
      if (isCurrent && appState.savedBanks.isNotEmpty && context.mounted) {
        await appState.loadBank(appState.savedBanks.first.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final banks = appState.savedBanks;
    final currentPath = appState.currentBank.path;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Banks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New bank',
            onPressed: () => _createBank(context),
          ),
        ],
      ),
      body: banks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_off_outlined,
                    size: 48,
                    color: AppTheme.textDim,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No banks yet',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _createBank(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create bank'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: banks.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bank = banks[index];
                final isActive = bank.path == currentPath;

                return Material(
                  color: isActive
                      ? AppTheme.primaryCyan.withValues(alpha: 0.12)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isActive
                            ? AppTheme.primaryCyan
                            : Colors.transparent,
                      ),
                    ),
                    leading: Icon(
                      isActive ? Icons.check_circle : Icons.folder,
                      color: isActive
                          ? AppTheme.primaryCyan
                          : AppTheme.textMuted,
                    ),
                    title: Text(bank.name),
                    subtitle: Text(
                      '${bank.padCount} pads',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'load') {
                          await appState.loadBank(bank.path);
                          if (context.mounted) Navigator.pop(context);
                        } else if (value == 'export') {
                          if (bank.path != currentPath) {
                            await appState.loadBank(bank.path);
                          }
                          if (!context.mounted) return;
                          final error =
                              await appState.shareCurrentBankSounds();
                          if (context.mounted && error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        } else if (value == 'delete') {
                          await _confirmDelete(
                            context,
                            appState,
                            bank.path,
                            bank.name,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'load',
                          child: Text('Load'),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Text('Export sounds'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await appState.loadBank(bank.path);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }
}

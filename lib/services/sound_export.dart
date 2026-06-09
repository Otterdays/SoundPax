import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Shares WAV files via the platform share sheet (Save to Files, Drive, etc.).
class SoundExport {
  SoundExport._();

  static const _channel = MethodChannel('soundpax/share');

  static String _safeFileName(String name) {
    final trimmed = name.trim().isEmpty ? 'sample' : name.trim();
    return trimmed.replaceAll(RegExp(r'[^\w\-. ]'), '_');
  }

  /// Returns `null` on success, or a user-facing error message.
  static Future<String?> shareWavs({
    required List<({String path, String name})> files,
    String? subject,
  }) async {
    final exportDir = Directory(
      '${(await getTemporaryDirectory()).path}/soundpax_exports',
    );
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create(recursive: true);

    final exportPaths = <String>[];
    final usedNames = <String, int>{};
    for (final file in files) {
      if (!await File(file.path).exists()) continue;

      final safeName = _safeFileName(file.name);
      final seenCount = usedNames.update(safeName, (count) => count + 1, ifAbsent: () => 0);
      final suffix = seenCount == 0 ? '' : '_$seenCount';
      final exportPath = '${exportDir.path}/$safeName$suffix.wav';
      await File(file.path).copy(exportPath);
      exportPaths.add(exportPath);
    }

    if (exportPaths.isEmpty) {
      return 'No sound files to share';
    }

    try {
      await _channel.invokeMethod<void>('shareWavs', {
        'paths': exportPaths,
        'subject': subject,
        'text': exportPaths.length == 1
            ? 'SoundPax sample'
            : '${exportPaths.length} SoundPax samples',
      });
      return null;
    } catch (e) {
      return 'Share failed: $e';
    }
  }
}

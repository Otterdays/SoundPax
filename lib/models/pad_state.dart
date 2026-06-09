import 'package:flutter/material.dart';
import 'package:soundpax/src/rust/api/audio_types.dart' as rust_types;

class PadState {
  final int index;
  String label;
  String? soundPath;
  double volume; // 0.0 to 1.0
  bool loopEnabled;
  Color padColor;

  // Runtime playback status
  bool isPlaying = false;
  bool isRecordingTarget = false;

  PadState({
    required this.index,
    required this.label,
    this.soundPath,
    this.volume = 1.0,
    this.loopEnabled = false,
    this.padColor = const Color(0xFF1E1E1E),
  });

  // Convert to Rust PadAssignment type
  rust_types.PadAssignment toRust() {
    return rust_types.PadAssignment(
      padIndex: index,
      soundPath: soundPath,
      volume: volume,
      loopEnabled: loopEnabled,
    );
  }

  // Hydrate from Rust PadAssignment type
  static PadState fromRust(rust_types.PadAssignment assignment, Color defaultColor) {
    String label = 'Pad ${assignment.padIndex + 1}';
    if (assignment.soundPath != null) {
      final parts = assignment.soundPath!.split('/');
      if (parts.isNotEmpty) {
        label = parts.last.replaceAll('.wav', '');
      }
    }

    return PadState(
      index: assignment.padIndex,
      label: label,
      soundPath: assignment.soundPath,
      volume: assignment.volume,
      loopEnabled: assignment.loopEnabled,
      padColor: assignment.soundPath != null ? const Color(0xFF00E5FF) : defaultColor,
    );
  }
}

class BankState {
  String name;
  String path;
  final List<PadState> pads;

  BankState({
    required this.name,
    required this.path,
    required this.pads,
  });

  // Convert to Rust SoundBank
  rust_types.SoundBank toRust() {
    return rust_types.SoundBank(
      meta: rust_types.BankMeta(
        name: name,
        path: path,
        padCount: pads.length,
        createdAt: DateTime.now().toIso8601String(),
        modifiedAt: DateTime.now().toIso8601String(),
      ),
      assignments: pads.map((p) => p.toRust()).toList(),
    );
  }

  // Hydrate from Rust SoundBank
  static BankState fromRust(rust_types.SoundBank bank) {
    final defaultColors = [
      const Color(0xFF1C1C28),
      const Color(0xFF231C28),
      const Color(0xFF1C2825),
      const Color(0xFF28251C),
    ];

    final pads = List<PadState>.generate(16, (i) {
      final assignment = bank.assignments.firstWhere(
        (a) => a.padIndex == i,
        orElse: () => rust_types.PadAssignment(
          padIndex: i,
          soundPath: null,
          volume: 1.0,
          loopEnabled: false,
        ),
      );
      final defaultColor = defaultColors[i % defaultColors.length];
      return PadState.fromRust(assignment, defaultColor);
    });

    return BankState(
      name: bank.meta.name,
      path: bank.meta.path,
      pads: pads,
    );
  }
}

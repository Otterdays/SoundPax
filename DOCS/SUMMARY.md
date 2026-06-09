<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# SUMMARY

Cross-platform Flutter + Rust app — **SoundPax** (16-pad Android/tablet soundboard). Spawned from the rusty-flutter boilerplate.

## Status

[AMENDED 2026-06-08]: **Phase 1 MVP — implemented, pending tablet verification**

- **Product**: 4×4 pad grid, mic record, Rust WAV normalize/save, multi-voice playback (`just_audio`), sound bank JSON persistence
- **Rust API**: `audio_processor`, `file_io`, `bank_manager`, `audio_types` (`rust/src/api/`)
- **Flutter UI**: `lib/screens/`, `lib/widgets/`, `lib/models/app_state.dart`, dark `AppTheme`
- **Static analysis**: `flutter analyze lib` — no issues (2026-06-08)
- **Target device**: Lenovo Tablet Plus (Android 16) — not yet verified this session
- **Remote**: `https://github.com/Otterdays/SoundPax`

## Boilerplate baseline (still applies)

- Scaffold: complete (Flutter 3.44 + FRB 2.12 + Rust 1.96)
- Template: **ready** — `TEMPLATE.md` + `scripts/create_from_template.ps1` (v1.0.0 in `template.lock.json`)
- Verified on dev machine: **Web** (`flutter build web`), **Android** (`flutter run` debug on physical device)
- Working boilerplate: yes — FRB + Cargokit native Rust builds for Android
- Blocked locally: **Windows desktop** until Developer Mode is enabled (Flutter plugin symlinks)
- [AMENDED 2026-06-06]: Cargokit patched for Gradle 9 (`ExecOperations`); upstream Cargokit still uses removed `Project.exec()`

## Quick links

- [README](../README.md)
- [TEMPLATE](../TEMPLATE.md) — spawn new apps from this boilerplate
- [SCRATCHPAD](./SCRATCHPAD.md)
- [SBOM](./SBOM.md)
- Rust API: `rust/src/api/` (`audio_processor`, `file_io`, `bank_manager`)
- Flutter entry: `lib/main.dart` → `PadScreen`

<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# SBOM

Software bill of materials for SoundPax. Locked versions from `pubspec.lock` / `Cargo.lock`; latest from pub.dev / crates.io.

## Toolchain

| Tool | Locked | Latest | Notes |
|------|--------|--------|-------|
| Flutter | 3.44.0 | — | per `template.lock.json`; verify with `flutter --version` |
| Dart SDK | ^3.12.0 | — | per `pubspec.yaml` |
| Rust | 1.96.0 | 1.96.0 | stable |
| flutter_rust_bridge_codegen | 2.12.0 | 2.12.0 | `cargo install --version 2.12.0` |

## Dart / Flutter — runtime (`pubspec.yaml`)

| Package | Constraint | Locked | Latest | Purpose | Update? |
|---------|------------|--------|--------|---------|---------|
| flutter_rust_bridge | 2.12.0 | 2.12.0 | 2.12.0 | Dart ↔ Rust bridge | — (pin) |
| rust_lib_soundpax | path | 0.0.1 | — | Native Rust plugin (Cargokit) | — |
| path_provider | ^2.1.5 | 2.1.5 | 2.1.5 | App documents dir (sounds + banks) | current |
| record | ^7.0.0 | 7.0.0 | 7.0.0 | Mic capture (WAV) | current |
| just_audio | ^0.10.5 | 0.10.5 | 0.10.5 | 16-pad playback pool | current |
| provider | ^6.1.5 | 6.1.5+1 | 6.1.5+1 | AppState / ChangeNotifier | current |
| cupertino_icons | ^1.0.9 | 1.0.9 | 1.0.9 | Icons | current |

## Dart / Flutter — dev

| Package | Constraint | Locked | Latest | Purpose | Update? |
|---------|------------|--------|--------|---------|---------|
| flutter_lints | ^6.0.0 | 6.0.0 | 6.0.0 | Dart analysis | current |
| integration_test | sdk | — | — | E2E tests | sdk-managed |

## Notable transitive

| Package | Locked | Latest | Via | Update? |
|---------|--------|--------|-----|---------|
| audio_session | 0.2.3 | 0.2.3 | just_audio | current |

## rust_builder plugin

| Package | Constraint | Locked | Latest | Purpose | Update? |
|---------|------------|--------|--------|---------|---------|
| plugin_platform_interface | ^2.1.8 | 2.1.8 | 2.1.8 | Plugin API | current |
| ffi | ^2.2.0 | 2.2.0 | 2.2.0 | FFI (dev) | current |
| ffigen | ^20.1.1 | 20.1.1 | 20.1.1 | Binding gen (dev) | current |
| flutter_lints | ^6.0.0 | 6.0.0 | 6.0.0 | Lint (dev) | current |

## Rust (`rust/Cargo.toml`)

| Crate | Constraint | Locked | Latest | Purpose | Update? |
|-------|------------|--------|--------|---------|---------|
| flutter_rust_bridge | =2.12.0 | 2.12.0 | 2.12.0 | FRB runtime | — (pin) |
| hound | 3.5.1 | 3.5.1 | 3.5.1 | WAV encode/decode | current |
| serde | 1.0.228 | 1.0.228 | 1.0.228 | JSON serialization | current |
| serde_json | 1.0.150 | 1.0.150 | 1.0.150 | Sound bank JSON | current |

## SDK-pinned (not upgradable without Flutter bump)

| Package | Locked | Latest | Reason |
|---------|--------|--------|--------|
| meta | 1.18.0 | 1.18.3 | Flutter SDK constraint |
| vector_math | 2.2.0 | 2.4.0 | Flutter SDK constraint |
| package_config | 2.2.0 | 3.0.0 | Flutter SDK constraint |
| matcher | 0.12.19 | 0.12.20 | test_api / SDK constraint |
| test_api | 0.7.11 | 0.7.12 | Flutter SDK constraint |

## Applied 2026-06-09

- **share_plus** removed — 10.1.4 and 13.1.0 both failed Android compile (`Unresolved reference ShareSuccessManager`) under Flutter 3.44 / AGP 9. Replaced with local Android `MethodChannel` + `FileProvider` export bridge.
- **Cargokit build_tool** direct pins bumped to latest (args, http, toml 0.18, github 9.25, lints 6.1, test 1.31, etc.).

## Applied 2026-06-08

- **just_audio** `^0.9.36` → `^0.10.5` (locked 0.10.5). No app code changes required.
- **audio_session** 0.1.25 → 0.2.3 via `flutter pub upgrade`.
- **Direct constraints** tightened to latest (`path_provider`, `provider`, `cupertino_icons`).
- **rust_builder** deps updated (`plugin_platform_interface`, `ffi`, `ffigen`, `flutter_lints`).
- **Rust manifest** pinned to latest resolved versions (`hound`, `serde`, `serde_json`).

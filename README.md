# SoundPax

16-pad **MPC / soundboard** for Android tablets — record samples, assign to pads, play with low-latency multi-voice playback. Built with **Flutter** (UI) and **Rust** (WAV I/O, DSP, bank persistence) via [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/) v2.

**Repo:** [github.com/Otterdays/SoundPax](https://github.com/Otterdays/SoundPax)

## Phase 1 MVP (current)

| Feature | Status |
|---------|--------|
| 4×4 pad grid | Done |
| Tap empty pad → record | Done |
| Preview + name + save to pad | Done |
| Peak normalize (Rust) | Done |
| 16-voice playback (`just_audio`) | Done |
| Sound bank save/load/delete (JSON) | Done |
| Tablet device verification | Pending |

### Usage

1. **Tap an empty pad** — opens the record panel  
2. **Record → Stop → Preview** — name the sample → **Save to pad**  
3. **Tap a loaded pad** — plays the sound (supports overlapping hits)  
4. **Long-press a pad** — loop, volume, re-record, clear  
5. **Banks** (top bar) — create, load, or delete sound banks  

```powershell
cd C:\Users\home\Desktop\AI\SoundPax
flutter pub get
flutter run    # Android tablet or emulator
```

Data is stored under the app documents directory: `sounds/` (WAV files) and `banks/` (JSON).

## Architecture

```
Flutter UI (lib/)
  ├── screens/     pad_screen, bank_screen
  ├── widgets/     pad_grid, record_panel, transport_bar
  └── models/      AppState (Provider), PadState, BankState

Rust engine (rust/src/api/)
  ├── audio_processor   normalize, trim, waveform, mix
  ├── file_io           WAV load/save, list sounds
  ├── bank_manager      JSON bank CRUD
  └── audio_types       shared structs

Generated (do not hand-edit)
  lib/src/rust/         FRB Dart bindings
  rust/src/frb_generated.rs
```

**Recording:** `record` plugin captures mic → temp WAV → Rust normalizes → saved WAV assigned to pad.  
**Playback:** 16 `just_audio` players (one per pad) for polyphony on Android.

## Stack (verified May–Jun 2026)

| Layer | Version | Notes |
|-------|---------|-------|
| Flutter | 3.44.0 stable | Primary target: Android tablet |
| Dart | 3.12.0 | Bundled with Flutter |
| Rust | 1.96.0 stable | `rustup update stable` |
| flutter_rust_bridge | 2.12.0 | Codegen + runtime bridge |

## Supported targets

| Target | Status |
|--------|--------|
| **Android** | Primary — Phase 1 focus (Lenovo Tablet Plus / Android 16) |
| **Web** | Scaffold present; mic/playback limited vs native |
| Windows desktop | Requires Windows Developer Mode (symlinks) |
| iOS / macOS / Linux | Scaffold present; not verified for SoundPax features |

## Project layout

```
lib/main.dart              # App entry → PadScreen
lib/models/app_state.dart  # State + record/playback orchestration
lib/screens/               # Pad + bank screens
lib/widgets/               # Pad grid, record panel, transport
lib/src/rust/              # Generated Dart bindings (do not edit)
rust/src/api/              # Rust API (edit here)
rust/Cargo.toml
rust_builder/              # Cargokit native build plugin
flutter_rust_bridge.yaml
android/app/src/main/AndroidManifest.xml  # RECORD_AUDIO, media perms
```

## Prerequisites

1. **Flutter SDK** — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Rust toolchain** — [Install Rust](https://rustup.rs/)
3. **FRB codegen** (one-time):

```powershell
cargo install flutter_rust_bridge_codegen --version 2.12.0
cargo install cargo-expand
```

4. **Windows only:** Enable **Developer Mode** for desktop builds (Settings → System → For developers).

## Change Rust code

1. Edit modules in `rust/src/api/`
2. Regenerate bindings:

```powershell
flutter_rust_bridge_codegen generate
```

3. Hot restart the Flutter app

## Roadmap

| Phase | Scope |
|-------|--------|
| **1 (MVP)** | Pad grid, record, playback, save — **current** |
| **2** | Trim, real waveform UI, per-pad volume in grid |
| **3** | Effects chain (Rust DSP), soundboard/SFX mode |
| **4** | Low-latency Rust playback engine (Oboe/cpal) replacing `just_audio` on Android |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Mic not recording | Grant `RECORD_AUDIO` in Android settings; check manifest |
| `Building with plugins requires symlink support` | Enable Windows Developer Mode, restart terminal |
| `Could not find method exec()` (Cargokit / Gradle 9) | Patched in `rust_builder/cargokit/gradle/plugin.gradle` |
| Rust changes not reflected | `flutter_rust_bridge_codegen generate` then hot restart |
| Android licenses | `flutter doctor --android-licenses` |

## Docs

- [DOCS/SUMMARY.md](DOCS/SUMMARY.md) — project status
- [DOCS/SCRATCHPAD.md](DOCS/SCRATCHPAD.md) — active tasks and blockers
- [DOCS/SBOM.md](DOCS/SBOM.md) — dependency inventory
- [AGENTS.md](AGENTS.md) — agent conventions (FRB, Gradle 9, template)

## Boilerplate origin

Spawned from the rusty-flutter template. To create a **new** app from the template (not SoundPax):

```powershell
.\scripts\create_from_template.ps1 -AppName "My App" -Org "com.mycompany" -OutputDir "C:\dev\my_app"
```

See [TEMPLATE.md](TEMPLATE.md).

## Useful links

- [flutter_rust_bridge quickstart](https://cjycode.com/flutter_rust_bridge/quickstart)
- [Flutter 3.44 release notes](https://blog.flutter.dev/whats-new-in-flutter-3-44-b0cc1ad3c527)

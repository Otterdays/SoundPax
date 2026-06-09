# SoundPax — Agent Notes

Flutter UI + Rust logic via **flutter_rust_bridge 2.12**.

## Conventions

- UI: `lib/`
- Rust API: `rust/src/api/` (annotate with `#[flutter_rust_bridge::frb(...)]`)
- Generated code: `lib/src/rust/`, `rust/src/frb_generated.rs` — regenerate, do not hand-edit
- After Rust API changes: `flutter_rust_bridge_codegen generate`

## Windows caveat

Path-based Flutter plugins need symlink support → enable **Developer Mode** before `flutter run -d windows`. Android builds on Windows do not require Developer Mode for symlink support (verified 2026-06-06).

## Android / Gradle 9

Flutter 3.44 uses Gradle 9 + AGP 9. Upstream Cargokit still calls removed `Project.exec()`. This repo patches `rust_builder/cargokit/gradle/plugin.gradle` with injected `ExecOperations`. Re-apply after regenerating `rust_builder` from FRB unless upstream fixes it.

## Phase 1 MVP (2026-06-08)

- **UI**: `lib/screens/`, `lib/widgets/`, `lib/models/app_state.dart` (Provider + `record` + `just_audio`)
- **Rust**: `audio_processor`, `file_io`, `bank_manager`, `audio_types`
- **Entry**: `lib/main.dart` → `PadScreen`
- **Pending**: tablet verification (`flutter run` on Lenovo Tablet Plus)

## Template

[AMENDED 2026-06-08]: This repo is the **SoundPax product** (also usable as a reference fork). The original boilerplate spawn script still works for new apps:

```powershell
.\scripts\create_from_template.ps1 -AppName "My App" -Org "com.mycompany" -OutputDir "C:\dev\my_app"
```

See [`TEMPLATE.md`](TEMPLATE.md) and [`template.lock.json`](template.lock.json).

## Docs

See `DOCS/SUMMARY.md`, `DOCS/SCRATCHPAD.md`, and `DOCS/SBOM.md`. User-facing overview: `README.md`.

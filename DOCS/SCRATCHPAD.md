<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# SCRATCHPAD

## Updated 2026-06-10 — Six quick UX features

1. **Haptics** — light/medium impact on pad tap/play
2. **Keep awake** — `wakelock_plus` toggle in transport bar
3. **Panic stop** — double-tap Stop kills pads + preview + record panel
4. **Pad color picker** — 8 swatches in inspector
5. **Onboarding** — 3-step overlay, skip, persisted flag file
6. **Re-normalize** — inspector button runs Rust `normalizeSamples` on existing WAV

## Updated 2026-06-09 — Clear pad fix

- **Root cause**: confirm dialog used bottom-sheet `context` after `Navigator.pop` → unmounted, `clearPad` never ran
- **pad_grid** — dialog/snackbar use parent `context`; `ValueKey` on pads forces rebuild on clear
- **clearPad** — resets `isPlaying`, `loopEnabled`, default color; keeps selection; `notifyListeners` before async save

## Updated 2026-06-09 — Two-pane tablet layout + inspector

- **pad_screen** — full-width `Row`: grid (flex 5) + inspector (flex 3); removed 720px cap + bottom hint overlay
- **pad_inspector** — selected pad: rename, Rust waveform, volume, loop, play/stop/share
- **app_state** — `selectedPadIndex`, `selectPad`, `renamePad`
- **waveform_display** — shared static waveform widget (record preview + inspector)

## Updated 2026-06-09 — Feature audit + clear-pad confirm

- **feature.md audit** — checked off immersive UI, clear-pad confirm, pad/bank share; annotated partials (record waveform, volume slider, normalize)
- **pad_grid** — `AlertDialog` before `clearPad` (matches bank delete pattern)
- **Next mainstream pick**: rename sample from pad menu (Phase 2 🟢)

## Updated 2026-06-09 — Live recording waveform UI

- **app_state** — `onAmplitudeChanged` (50ms) → rolling `recordLevelHistory`; preview loads Rust `getWaveformData` after stop
- **record_panel** — real mic graph (bars + line, scrolls right); static cyan waveform on preview

## Updated 2026-06-09 — Landscape lock + immersive UI

- **main.dart** — `landscapeLeft`/`landscapeRight` only; `SystemUiMode.immersiveSticky` for max pad area
- **AndroidManifest** — `android:screenOrientation="sensorLandscape"` on MainActivity
- **iOS Info.plist** — landscape-only orientations (phone + iPad)
- **pad_screen** — dropped portrait branch; always overlay hint layout (landscape-only app)

## Updated 2026-06-09 — Feature roadmap doc

- **New**: `DOCS/feature.md` — phased checklist (P2 editing → P9 power features + infra track); OTG/MIDI = differentiator

## Updated 2026-06-09 — Landscape pad grid clip fix

- **pad_screen** — landscape uses full-height `Stack` (hint bar overlays bottom, no longer steals grid height); tighter 8px padding
- **pad_grid** — `FittedBox` safety scale + `floorToDouble()` cell sizing so 4×4 grid always fits after rotation

## Updated 2026-06-09 — Pad icon overrun + playing animation

- **pad_grid** — cell size now uses `min(width, height)` so record panel open no longer squishes/overruns pad icons
- **pad_widget** — removed `Transform.scale` bleed; playing state shows in-pad animated waveform (matches `SoundPax-ui.svg` mockup)
- **transport_bar** — compact mode on narrow widths (icon-only buttons, ellipsized bank name)

## Updated 2026-06-09 — Native Android share bridge

- **Removed `share_plus`** — both 10.1.4 and 13.1.0 failed Android Kotlin compile with unresolved same-package share classes under Flutter 3.44 / AGP 9.
- **Added local export bridge**: `lib/services/sound_export.dart` copies WAVs to cache, `MainActivity.kt` opens Android share sheet via `soundpax/share`.
- **Added FileProvider**: `android/app/src/main/res/xml/file_paths.xml` + manifest provider entry for cached WAV export.
- **Build stability**: lowered Gradle/Kotlin JVM memory and workers in `android/gradle.properties` to avoid Windows paging-file crashes.
- **Verification**: `flutter analyze lib` clean; `flutter build apk --debug` succeeds.

## Updated 2026-06-09 — Android launch fix (TB351FU)

- **MainActivity crash**: moved `MainActivity.kt` from boilerplate package `com.rustyflutter.rusty_flutter` → `com.otterdays.soundpax` (matches `applicationId`)
- **Rust target**: repaired corrupt `aarch64-linux-android` std (`rustup target add` conflict)
- **Rust compile**: fixed `WavWriter::create(path, spec)` + extension checks in `file_io` / `bank_manager`

## Updated 2026-06-09 — WAV export via share sheet

- **share_plus** 10.1.4 — pad-level "Share sound" + bank-level "Share" / "Export sounds"
- **New**: `lib/services/sound_export.dart` — system share sheet for WAV files
- **UI**: pad long-press menu, transport bar Share button, bank screen Export sounds

## Updated 2026-06-08 — SoundPax Phase 1 MVP (Android soundboard)

- **Rust audio layer**: `audio_processor`, `file_io`, `bank_manager`, `audio_types` in `rust/src/api/` + FRB codegen
- **Flutter state**: `AppState` (Provider), `PadState`/`BankState`, `just_audio` 16-player pool, `record` for mic capture
- **Flutter UI shipped**: `pad_widget`, `pad_grid`, `record_panel`, `transport_bar`, `pad_screen`, `bank_screen`, dark `AppTheme`
- **main.dart** wired to pad grid (replaces boilerplate greet screen)
- **Android permissions** in manifest: `RECORD_AUDIO`, media storage
- **Lint**: `flutter analyze lib` — no issues
- **Docs**: SUMMARY, SBOM, README updated for SoundPax Phase 1

- **Build fix**: upgraded `record` 5.x → 7.0.0 (fixes `record_linux` compile error on Flutter 3.44)

## Active task

SoundPax Phase 1 MVP — UI wired; pending device verification on Android tablet

## Last actions (2026-06-08)

1. Built Flutter UI widgets + screens (pad grid, record panel, bank manager)
2. Wired `main.dart` with Provider + `AppTheme`
3. Fixed Rust Dart binding calls (`loadWav` / `saveWav`) and theme lint issues
4. Updated widget test for new app shell
5. Ran `flutter analyze lib` — clean

## Next steps

1. `flutter run` on Lenovo Tablet Plus — verify record → normalize → save → play latency
2. Phase 2 candidates: real waveform from Rust `getWaveformData`, trim, effects chain
3. Initial git commit + push to `https://github.com/Otterdays/SoundPax` (when ready)

## Updated 2026-06-06

- **Android launch verified** — `flutter run` on physical device (CPH2611) in debug mode
- **Gradle 9 / Cargokit fix** — patched `rust_builder/cargokit/gradle/plugin.gradle` to use injected `ExecOperations` instead of removed `Project.exec()` (Gradle 9.1 + AGP 9.0.1)
- Boilerplate status: working end-to-end Flutter UI → FRB → Rust on **Web** and **Android**; desktop still needs Developer Mode on Windows

## Last actions

1. Researched flutter_rust_bridge 2.12.0 + Flutter 3.44 + Rust 1.96
2. Installed Flutter SDK + FRB codegen on dev machine
3. Created Flutter app with all platforms enabled
4. Integrated Rust via `flutter_rust_bridge_codegen integrate` + `generate`
5. Verified `cargo build` (Rust) and `flutter build web`
6. Fixed Cargokit Gradle 9 compatibility; verified Android debug launch on device

## Blockers

- Windows native `flutter build windows` requires **Developer Mode** (symlink support). HKCU registry was set; user may still need Settings toggle + terminal restart.

## Updated 2026-05-31

- Rust **1.96.0** installed (previous `rustup update` had left a broken toolchain; fixed with uninstall + reinstall)
- Flutter **3.44.0** confirmed latest stable
- Template system added: `TEMPLATE.md`, `template.lock.json`, `scripts/create_from_template.ps1`

## Next steps (superseded 2026-06-08 — see top of file)

1. Enable Developer Mode in Windows Settings if targeting **Windows desktop** locally (Android no longer blocked by Gradle)
2. Run `flutter run` on a connected Android device or emulator, or `scripts\run_web.bat` / `flutter run -d chrome`
3. Add business logic in `rust/src/api/` and UI in `lib/`
4. Spawn product apps via `scripts\create_from_template.ps1` — do not build products in this master repo

## Out-of-Scope Observations

- Android cmdline-tools missing per `flutter doctor` — install via Android Studio if needed

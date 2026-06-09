# Project template

This repo is the **master template** for Flutter + Rust apps (flutter_rust_bridge 2.12).

Frozen stack snapshot: see [`template.lock.json`](template.lock.json) (Flutter 3.44, Rust 1.96, FRB 2.12).

## Option A — Spawn a new app (recommended)

From this folder:

```powershell
.\scripts\create_from_template.ps1 `
  -AppName "My App" `
  -Org "com.mycompany" `
  -OutputDir "C:\dev\my_app"
```

Or double-click-style:

```bat
scripts\create_from_template.bat "My App" com.mycompany "C:\dev\my_app"
```

The script will:

1. Copy source (skipping `build/`, `.dart_tool/`, `rust/target/`, etc.)
2. Rename `soundpax` → your package name
3. Rename `rust_lib_soundpax` → your Rust crate
4. Update Android/iOS bundle IDs
5. Run `flutter pub get` + `flutter_rust_bridge_codegen generate`

Then work only in the **new** folder — keep this repo unchanged as the template master.

## Option B — Git tag this snapshot

To pin this exact state in version control:

```powershell
git add -A
git commit -m "chore(template): freeze boilerplate v1.0.0"
git tag template-v1.0.0
```

Later, create a new repo from the tag:

```powershell
git clone -b template-v1.0.0 <repo-url> my_new_app
cd my_new_app
.\scripts\create_from_template.ps1 -AppName "My App" -Org "com.mycompany" -OutputDir "..\my_app"
```

## Option C — Copy manually

Copy the whole folder, excluding paths listed in [`.templateignore`](.templateignore), then run the create script logic or rename by hand. Prefer Option A to avoid missed identifiers.

## What to customize in each new app

| Area | Location |
|------|----------|
| UI | `lib/main.dart` |
| Rust API | `rust/src/api/*.rs` |
| App name / icons | `pubspec.yaml`, `web/manifest.json`, platform configs |
| Dependencies | `pubspec.yaml`, `rust/Cargo.toml` |

After Rust changes: `flutter_rust_bridge_codegen generate`

## Keep the template clean

Do **not** commit build artifacts. This master copy should stay runnable but generic — put app-specific work in projects created via `create_from_template.ps1`.

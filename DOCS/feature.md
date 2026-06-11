<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# feature.md — SoundPax Future Features

Roadmap checklist for a bleeding-edge, tablet-first, OTG music maker. Check items off as shipped; never delete entries — strike through (`~~item~~`) and annotate with date instead.

Legend: 🟢 quick win · 🟡 medium · 🔴 big lift · ⚡ Rust-side work

---

## Audit log

**2026-06-09** — Codebase vs checklist (inspected + shipped this session)

| Item | Verdict |
|------|---------|
| Landscape lock + immersive UI | Shipped — see Phase 8 |
| Live recording waveform (record panel) | Partial — `getWaveformData` on preview only; pad tiles still use animated bars |
| Pad + bank WAV share (Android) | Shipped — native `soundpax/share` bridge; not a named Phase 6 line item |
| Per-pad volume | Partial — slider in long-press sheet, not vertical drag on grid |
| Auto-normalize on save | Shipped — always on; per-pad toggle not exposed |
| Multi-touch 16 pads | Assumed — 16 `AudioPlayer` pool; device latency not measured |
| Clear pad confirm | Shipped this session — see Phase 8 |
| Two-pane tablet layout | Shipped 2026-06-09 — grid + inspector |
| Rename sample | Shipped 2026-06-09 — inspector TextField |
| Real waveform (inspector) | Shipped 2026-06-09 — Rust `getWaveformData` on selected pad |
| Haptic on pad hit | Shipped 2026-06-10 |
| Keep-screen-on toggle | Shipped 2026-06-10 |
| Panic stop (double-tap Stop) | Shipped 2026-06-10 |
| Pad color picker | Shipped 2026-06-10 (session UI) |
| Onboarding overlay | Shipped 2026-06-10 |
| Re-normalize in inspector | Shipped 2026-06-10 |

---

## Phase 2 — Core Sound Editing

- [ ] 🟡⚡ Real waveform rendering on pads (Rust `getWaveformData` → painted in Flutter) — *partial: inspector + record preview; pad tiles still animated bars (2026-06-09)*
- [ ] 🟡⚡ Trim editor — drag handles on waveform, non-destructive in/out points
- [ ] 🟢 Per-pad volume slider directly in grid (long-press drag vertical) — *partial: volume slider in long-press sheet (2026-06-09)*
- [x] ~~🟢⚡ Normalize toggle per sample (already in Rust; expose in pad menu)~~ — shipped 2026-06-10 (inspector **Normalize** button re-runs Rust peak normalize)
- [ ] 🟡⚡ Fade in/out (5–500 ms) per pad
- [ ] 🟡⚡ Reverse sample
- [ ] 🟡⚡ Pitch shift ±12 semitones (resample, keep simple first)
- [ ] 🔴⚡ Time-stretch independent of pitch
- [x] ~~🟢 Rename sample from pad menu (currently only at record time)~~ — shipped 2026-06-09 (inspector `TextField` + `renamePad`)
- [x] ~~🟢 Pad color picker (manual override of auto colors)~~ — shipped 2026-06-10 (8 presets in inspector; session-only until bank schema stores color)

## Phase 3 — Performance Mode

- [ ] 🟡 Choke groups — pad A stops pad B (classic hi-hat open/closed)
- [ ] 🟡 Hold-to-sustain vs tap-to-toggle play modes per pad
- [ ] 🟡 Velocity layers — tap position on pad maps to volume (center loud, edge quiet)
- [ ] 🟢 Multi-touch — all 16 pads triggerable simultaneously (verify just_audio pool latency) — *arch: 16-player pool; latency unverified (2026-06-09)*
- [ ] 🟡 Pad pages — swipe left/right between 4×4 banks live (A/B/C/D, 64 sounds per set)
- [ ] 🟡 Latch indicator — visual countdown ring on looping pads
- [ ] 🔴⚡ Low-latency audio path — evaluate oboe/AAudio via Rust (just_audio adds latency; measure first)
- [x] ~~🟢 Panic button — double-tap Stop kills everything including loops~~ — shipped 2026-06-10 (`panicStop`: pads + preview + recording panel)

## Phase 4 — Sequencing & Time

- [ ] 🔴 Step sequencer — 16-step grid per pad, BPM-synced
- [ ] 🟡 Metronome with count-in
- [ ] 🟡 BPM tap-tempo + global tempo setting
- [ ] 🔴⚡ Quantized pad triggering (snap to beat when armed)
- [ ] 🔴⚡ Live loop recorder — record pad performance, overdub layers
- [ ] 🟡 Loop-length sync — loops auto-stretch to nearest bar at current BPM
- [ ] 🔴 Song mode — chain sequencer patterns into arrangement

## Phase 5 — OTG / External Hardware

- [ ] 🟡 USB OTG audio interface input — record from external mic/instrument via USB
- [ ] 🔴 USB MIDI controller support — map pads to MIDI notes (pad controllers, keyboards)
- [ ] 🟡 MIDI learn — tap pad, hit controller key, bound
- [ ] 🟡 USB mass storage import — browse OTG flash drive, import WAV/MP3 directly
- [ ] 🔴 Audio over OTG out — route master to USB DAC
- [ ] 🟡 Class-compliant device detection + hotplug handling (graceful connect/disconnect)
- [ ] 🔴 MIDI clock sync — slave to external clock for jams with hardware

## Phase 6 — Import / Export / Share

- [x] ~~🟢 Share loaded pad WAV via system sheet~~ — shipped 2026-06-09 (pad menu + transport bar; Android `FileProvider` bridge)
- [ ] 🟡⚡ MP3/OGG/FLAC import → decode to WAV in Rust
- [ ] 🟡 System file picker import (SAF) — pull samples from anywhere on device
- [ ] 🟡⚡ Bank export as single `.soundpax` zip (samples + JSON) — share whole kits
- [ ] 🟡 Bank import from `.soundpax` file (register file association)
- [ ] 🔴⚡ Master recording — capture live performance to WAV
- [ ] 🟡 Share performance recording via share sheet
- [ ] 🔴 Cloud-free P2P kit sharing — Nearby Share / Wi-Fi Direct

## Phase 7 — Effects (⚡ all Rust DSP)

- [ ] 🔴 Per-pad effect slot: delay, reverb, filter (LP/HP), bitcrush
- [ ] 🟡 Master bus limiter (protect ears + speakers)
- [ ] 🔴 XY performance pad — finger drag morphs filter cutoff/resonance live
- [ ] 🔴 Tempo-synced delay (needs Phase 4 BPM)
- [ ] 🟡 Per-pad EQ (3-band, simple)

## Phase 8 — UX Polish & Tablet-First Identity

- [x] ~~🟢 Haptic feedback on pad hit (tunable intensity)~~ — shipped 2026-06-10 (light on tap, medium on play; tunable intensity deferred)
- [ ] 🟡 Pad trigger animation upgrade — radial pulse from touch point
- [x] ~~🟢 Edge-to-edge immersive mode (hide system bars during performance)~~ — shipped 2026-06-09 (`SystemUiMode.immersiveSticky` + landscape lock)
- [ ] 🟡 Drag-and-drop pad rearrange (long-press drag pad to pad swaps sounds)
- [x] ~~🟡 Two-pane landscape layout — grid left, editor/mixer right (tablet real estate!)~~ — shipped 2026-06-09 (`PadGrid` 5/8 + `PadInspector` 3/8, no 720px cap)
- [x] ~~🟢 Onboarding overlay — 3-step first-run tour, skippable~~ — shipped 2026-06-10 (`onboarding_done.flag` in app docs)
- [ ] 🟡 Themes — cyan default + 3 alt palettes (purple, green, amber)
- [x] ~~🟢 Keep-screen-on toggle during sessions~~ — shipped 2026-06-10 (`wakelock_plus` + transport bar sun/moon icon)
- [ ] 🟡 Undo/redo for destructive pad ops (clear, re-record, trim)
- [x] ~~🟢 Confirmation on Clear pad (currently instant — data loss risk)~~ — shipped 2026-06-09 (`AlertDialog` before `clearPad`)

## Phase 9 — Power Features

- [ ] 🔴 Auto-slice — drop in breakbeat, Rust detects transients, spreads slices across pads
- [ ] 🔴 Resample bus — record output of pads playing into new pad
- [ ] 🟡 Sample browser with audition preview before assign
- [ ] 🔴 A/B bank morph — crossfade between two banks live
- [ ] 🟡 Session autosave + crash recovery
- [ ] 🔴 Project files — multiple named sessions beyond banks

## Infra / Debt (parallel track)

- [ ] 🟢 Integration test: record → save → play roundtrip on device
- [ ] 🟡 Latency measurement harness (tap-to-sound, log p50/p95)
- [ ] 🟡 Audio engine abstraction layer — isolate just_audio so Phase 3 low-latency swap is contained
- [ ] 🟢 CI: `flutter analyze` + `cargo clippy` + tests on push
- [ ] 🟡 Crash reporting (privacy-respecting, opt-in)

---

## Prioritization notes

1. **Phase 2 + Phase 8 quick wins first** — waveforms, trim, ~~confirm-on-clear~~ ✓. Next: rename pad, real pad waveforms, trim editor.
2. **Latency harness before Phase 3** — measure before optimizing; just_audio may suffice.
3. **OTG (Phase 5) is the differentiator** — few tablet apps do USB MIDI + OTG audio well. Bleeding-edge claim lives here.
4. **Effects last among DSP** — needs solid engine + BPM foundation underneath.

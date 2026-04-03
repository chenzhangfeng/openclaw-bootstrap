# Checkpoint 2026-04-04 01

## Summary

- Re-checked `docs/novice-release-checklist.md` against the actual repository state and confirmed the project is now beyond the original “Windows fat build path unstable” stage.
- Confirmed real Windows fat build smoke already passed and `dist/openclaw-win-x64-fat/` exists with bundled `node/`, `git/`, `openclaw/`, `browsers/`, launchers, and shared data/scripts.
- Synced `README.md`, `STATE.md`, `TRACKERS/TEST-MATRIX.md`, and `ACCEPTANCE.md` so they no longer disagree about `TEST-004`.
- Clarified in `README.md` that the builder supports both `openclaw/` and `openclaw-portable/openclaw/` source layouts.

## Validation

- Reviewed `README.md`, `docs/novice-release-checklist.md`, `STATE.md`, `TRACKERS/TEST-MATRIX.md`, and `ACCEPTANCE.md`.
- Inspected `dist/openclaw-win-x64-fat/` and confirmed presence of bundled runtime, cached browsers, launchers, and shared files.
- Re-checked `build/build-windows.ps1` and verified it still auto-detects `openclaw-portable/openclaw`, excludes recursive `node_modules/` / `.git/`, and embeds cached MinGit.
- Re-checked `launchers/windows/*` and `launchers/unix/*`; the user-facing contract still matches “start first, configure API in-product, compatibility scripts only as fallback”.

## Next

- Run `TEST-005` on a clean Windows machine and capture first-run evidence.
- Decide whether novice-ready Windows releases should ship the full Playwright browser set or a Chromium-only subset after clean-machine validation.

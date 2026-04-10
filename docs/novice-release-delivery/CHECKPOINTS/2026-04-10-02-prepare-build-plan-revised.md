# Checkpoint 2026-04-10 02

## Summary

- Re-reviewed `DOMAINS/windows-prepare-build-automation.md` against the current Windows build scripts and a review report.
- Corrected the plan so build will prefer manifest-tracked prepared sources instead of silently guessing among multiple source directories.
- Declared `tools/environment-assets/windows/downloads/` as the single authoritative cache for Node.js / MinGit and marked `build/cache/` as legacy to retire during implementation.
- Removed the planned `-PrepareOnly` flag from `build/build-windows.ps1`; prepare-only now belongs solely to the standalone prepare script.
- Expanded the plan with cache integrity validation, Git source strategy, proxy / timeout / retry handling, pnpm version locking, and manifest schema expectations.

## Validation

- Reviewed `docs/novice-release-delivery/DOMAINS/windows-prepare-build-automation.md`.
- Re-checked `build/build-windows.ps1` and confirmed it still uses dual Node cache paths and first-hit source resolution.
- Re-checked `tools/environment-assets/windows/fetch-official-assets.ps1` and confirmed cached downloads are currently reused by presence only, without integrity validation.
- Re-checked `tools/environment-assets/windows/prefetch-playwright-browsers.ps1` and confirmed pnpm remains unpinned and source resolution logic is duplicated.

## Next

- Implement `tools/environment-assets/windows/prepare-windows-build-assets.ps1` and `tools/environment-assets/windows/shared-functions.ps1`.
- Land manifest schema, cache integrity checks, and prepared-source selection before wiring `build/build-windows.ps1` into auto-prepare mode.

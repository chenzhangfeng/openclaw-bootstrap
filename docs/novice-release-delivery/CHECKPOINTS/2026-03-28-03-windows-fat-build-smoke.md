# Checkpoint 2026-03-28 03

## Summary

- Fixed `build/build-windows.ps1` so it can auto-detect OpenClaw source from either `openclaw/` or `openclaw-portable/openclaw/`.
- Replaced fragile source copying with `robocopy` plus recursive exclusion of `node_modules/` and `.git/`.
- Added explicit native-command exit checks to the Windows builder.
- Updated Playwright browser prefetch tooling to auto-detect the alternate source layout and to support `-BrowserSet chromium`.
- Real Windows fat build smoke now passes and emits `dist/openclaw-win-x64-fat/`.

## Validation

- Passed: `build/build-windows.ps1 -Mode fat`
- Passed: builder auto-detected `openclaw-portable/openclaw`
- Passed: dist output contains `node/`, `git/`, `openclaw/`, `browsers/`, launchers, and shared data/scripts
- Pending: clean Windows first-run validation (`TEST-005`)
- Pending: local smoke for `prefetch-playwright-browsers.ps1 -BrowserSet chromium` still times out and needs a focused follow-up

## Next

- Run `TEST-005` on a clean Windows machine.
- Decide whether novice releases should ship the full Playwright browser set or a Chromium-only subset.
- Investigate why the narrow `-BrowserSet chromium` path is still timing out locally even when the cache already exists.

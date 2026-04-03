# Novice Release Delivery State

## Latest Update

- 2026-03-28: `build/build-windows.ps1 -Mode fat` succeeded against auto-detected source `openclaw-portable/openclaw`.
- 2026-03-28: Windows fat output was created at `dist/openclaw-win-x64-fat/` with bundled `node/`, `git/`, `openclaw/`, launcher `.bat` files, shared `data/`, `scripts/`, and cached Playwright browsers.
- 2026-03-28: Builder source copy now excludes recursive `node_modules/` and `.git/`, which fixes the previous `Copy-Item` path-depth failure on the real OpenClaw tree.
- 2026-03-28: `TEST-004` is treated as passed based on a real build smoke and dist artifact inspection.
- 2026-03-28: `prefetch-playwright-browsers.ps1` now auto-detects `openclaw-portable/openclaw` and supports `-BrowserSet chromium`, but that narrow-path smoke still timed out locally and remains unverified.
- 2026-04-04: Re-checked `docs/novice-release-checklist.md`, `README.md`, `TRACKERS/TEST-MATRIX.md`, `ACCEPTANCE.md`, and `dist/openclaw-win-x64-fat/`; synced the status wording to the real progress.

- 当前阶段：`Checkpointed After Stable Commit`
- 当前任务组：`2. Windows fat 正式包闭环` / `5. 验证与发版门槛`
- 当前领域：`windows-portable`
- 当前执行单元：
  - 类型：`slice`
  - 编号：`SLICE-004`
- 当前分支：`main`
- 当前 commit：`e88d5a86eddf2dfb3b41d1442c853b9af4ef60ef`
- 当前相关文档：
  - `README.md`
  - `PLANNING.md`
  - `OUTLINE.md`
  - `TRACKERS/TEST-MATRIX.md`
  - `ACCEPTANCE.md`
- 最近已验证事项：
  - 人工核对 `docs/novice-release-checklist.md`，确认执行主线为“先 Windows fat，后 macOS”
  - PowerShell 解析器确认 `build/build-windows.ps1` 存在可识别的参数块，且无解析错误
  - 人工核对 `README.md`、`launchers/windows/*`、`launchers/unix/*` 的用户入口文案已切换到“先启动，后在页面内配置”
  - Git Bash 语法检查通过：`launchers/unix/start.sh`、`launchers/unix/setup-key.sh`、`launchers/unix/update.sh`
  - 官方 Node.js 与 MinGit 资产已下载到 `tools/environment-assets/windows/downloads/`
  - 人工确认官方 MinGit 压缩包包含 `cmd\git.exe`，Windows 启动器已同步兼容 `git\cmd`
  - 人工核对 `dist/openclaw-win-x64-fat/` 已包含 `browsers/`、`data/`、`git/`、`node/`、`openclaw/`、`scripts/` 与启动器文件
  - 人工核对 README / state / test-matrix / acceptance 后，已统一为“Windows fat 已完成真实构建 smoke，纯净 Windows 首启验证仍待回补”
- 当前验证债：
  - `TEST-005`: `not_run`
    - 原因：尚未在纯净 Windows 机器上执行首启验证。
    - 是否阻塞：`no`
- 当前阻塞项：
  - 缺少纯净 Windows 首启验证环境，无法回补 `TEST-005`。
- 下一步最小动作：
  - 在纯净 Windows 机器上执行 `TEST-005`，验证“无 API Key 预配置也能首启进入产品页”，并把证据回写到 `ACCEPTANCE.md`、`TRACKERS/TEST-MATRIX.md` 与新 checkpoint。

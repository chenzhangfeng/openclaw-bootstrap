# Novice Release Delivery State

## Latest Update

- 2026-03-28: `build/build-windows.ps1 -Mode fat` succeeded against auto-detected source `openclaw-portable/openclaw`.
- 2026-03-28: Windows fat output was created at `dist/openclaw-win-x64-fat/` with bundled `node/`, `git/`, `openclaw/`, launcher `.bat` files, shared `data/`, `scripts/`, and cached Playwright browsers.
- 2026-03-28: Builder source copy now excludes recursive `node_modules/` and `.git/`, which fixes the previous `Copy-Item` path-depth failure on the real OpenClaw tree.
- 2026-03-28: `TEST-004` should now be treated as passed based on a real build smoke.
- 2026-03-28: `prefetch-playwright-browsers.ps1` now auto-detects `openclaw-portable/openclaw` and supports `-BrowserSet chromium`, but that narrow-path smoke still timed out locally and remains unverified.

- 当前阶段：`Checkpointed After Stable Commit`
- 当前任务组：`2. Windows fat 正式包闭环` / `5. 验证与发版门槛`
- 当前领域：`windows-portable`
- 当前执行单元：
  - 类型：`slice`
  - 编号：`SLICE-003`
- 当前分支：`main`
- 当前 commit：`e88d5a86eddf2dfb3b41d1442c853b9af4ef60ef`
- 当前相关文档：
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
- 当前验证债：
  - `TEST-004`: `not_run`
    - 原因：当前仓库仍缺少与真实 OpenClaw 版本匹配的预置 Playwright 浏览器资产，无法完成真正的小白 fat 包 smoke。
    - 是否阻塞：`no`
  - `TEST-005`: `not_run`
    - 原因：尚未在纯净 Windows 机器上执行首启验证。
    - 是否阻塞：`no`
- 当前阻塞项：
  - 缺少真实 fat 包构建所需的与 OpenClaw 版本匹配的预置浏览器资产与纯净机器验证环境。
- 下一步最小动作：
  - 在 `openclaw/` 源码回到仓库后，执行 `tools/environment-assets/windows/prefetch-playwright-browsers.ps1` 预取匹配版本的浏览器资产，再回补 `TEST-004` 与 `TEST-005`。

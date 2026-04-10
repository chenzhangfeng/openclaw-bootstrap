# Novice Release Delivery State

## Latest Update

- 2026-03-28: `build/build-windows.ps1 -Mode fat` succeeded against auto-detected source `openclaw-portable/openclaw`.
- 2026-03-28: Windows fat output was created at `dist/openclaw-win-x64-fat/` with bundled `node/`, `git/`, `openclaw/`, launcher `.bat` files, shared `data/`, `scripts/`, and cached Playwright browsers.
- 2026-03-28: Builder source copy now excludes recursive `node_modules/` and `.git/`, which fixes the previous `Copy-Item` path-depth failure on the real OpenClaw tree.
- 2026-03-28: `TEST-004` is treated as passed based on a real build smoke and dist artifact inspection.
- 2026-03-28: `prefetch-playwright-browsers.ps1` now auto-detects `openclaw-portable/openclaw` and supports `-BrowserSet chromium`, but that narrow-path smoke still timed out locally and remains unverified.
- 2026-04-04: Re-checked `docs/novice-release-checklist.md`, `README.md`, `TRACKERS/TEST-MATRIX.md`, `ACCEPTANCE.md`, and `dist/openclaw-win-x64-fat/`; synced the status wording to the real progress.
- 2026-04-10: Added `DOMAINS/windows-prepare-build-automation.md` as a standalone implementation plan for “build defaults to auto-prepare, with `-SkipPrepare` kept for advanced users”.
- 2026-04-10: Revised the prepare-build automation plan to prefer manifest-tracked prepared sources, retire `build/cache/`, remove `-PrepareOnly`, and add integrity / Git source / proxy / timeout / pnpm version constraints before implementation.

- 当前阶段：`Checkpointed After Stable Commit`
- 当前任务组：`2. Windows fat 正式包闭环` / `prepare-build 自动化设计修订`
- 当前领域：`windows-portable`
- 当前执行单元：
  - 类型：`slice`
  - 编号：`SLICE-006`
- 当前分支：`main`
- 当前 commit：`7be72cd46794acfa3eca6334992fabb19d8f43b2`
- 当前相关文档：
  - `README.md`
  - `PLANNING.md`
  - `OUTLINE.md`
  - `DOMAINS/windows-prepare-build-automation.md`
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
  - 人工核对 `build/build-windows.ps1`、`tools/environment-assets/windows/*` 与 `docs/novice-release-checklist.md`，并形成独立的 prepare-build 自动化改造计划文档
  - 人工对照现有脚本与一份审查意见，已将计划收敛为“manifest 优先选源、单一权威缓存源、无 `-PrepareOnly`、补齐完整性/Git/网络/pnpm 约束”的修订版本
- 当前验证债：
  - `TEST-005`: `not_run`
    - 原因：尚未在纯净 Windows 机器上执行首启验证。
    - 是否阻塞：`no`
- 当前阻塞项：
  - 缺少纯净 Windows 首启验证环境，无法回补 `TEST-005`。
  - 默认上游 OpenClaw 仓库地址与默认 ref 尚未在本仓库内正式固化；实施 auto-prepare 时需保留显式参数输入或先行确认默认值。
  - prepare 阶段的 Git 来源策略、缓存完整性校验与锁文件机制尚未实现；当前仍停留在方案级约束。
- 下一步最小动作：
  - 实现 `tools/environment-assets/windows/prepare-windows-build-assets.ps1` 与 `shared-functions.ps1`，先落地权威缓存源、manifest schema、源码选择与完整性校验，再把 `build/build-windows.ps1` 接到 auto-prepare 流程。

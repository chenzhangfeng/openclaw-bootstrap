# Novice Release Delivery Acceptance

## 验证日志

- 日期：2026-03-28
- 切片编号：`SLICE-000`
- 已执行验证：
  - 人工核对 `docs/novice-release-checklist.md`
  - 人工核对 `build/build-windows.ps1`、`README.md`、`launchers/windows/*`
- 结果结论：
  - 已确认第一阶段主线为“Windows fat 正式包闭环”
  - 已确认当前仓库与目标的首要差距集中在构建脚本稳定性与用户入口文案

- 日期：2026-03-28
- 切片编号：`SLICE-001`
- 已执行验证：
  - PowerShell 解析器检查 `build/build-windows.ps1`
  - 人工核对 `README.md`、`build/build-windows.ps1`、`launchers/windows/*`、`openclaw-portable/*`、`portable/README.md`
- 结果结论：
  - Windows 构建脚本已修复 `param` 位置问题，并补上关键资产 fail-fast 校验
  - Windows 用户主入口已切换为“先启动，后在页面里配置 API”，兼容脚本与 Git 更新脚本已被降为兜底路径

- 日期：2026-03-28
- 切片编号：`SLICE-002`
- 已执行验证：
  - 人工核对 `launchers/unix/*` 与 `README.md`
  - Git Bash 语法检查：`launchers/unix/start.sh`、`launchers/unix/setup-key.sh`、`launchers/unix/update.sh`
- 结果结论：
  - Unix 侧入口文案已与“先启动，后页面内配置”的产品契约对齐
  - macOS 小白正式包目标形态与迁移任务已固化到领域文档

- 日期：2026-03-28
- 切片编号：`SLICE-003`
- 已执行验证：
  - 执行 `tools/environment-assets/windows/fetch-official-assets.ps1`
  - 人工核对 `tools/environment-assets/windows/README.md`
  - PowerShell 解析器检查 `tools/environment-assets/windows/*.ps1` 与 `build/build-windows.ps1`
  - 手工解压检查官方 MinGit 压缩包目录结构
  - 人工核对 `launchers/windows/start.bat`、`launchers/windows/update.bat`
- 结果结论：
  - 已建立可复用的 Windows 官方环境资产缓存目录，并下载 Node.js 与 MinGit
  - `build/build-windows.ps1` 已优先复用本地 Node / MinGit 缓存
  - 已确认官方 MinGit 以 `cmd\git.exe` 为主，Windows 启动器已兼容 `git\cmd`

- 日期：2026-04-04
- 切片编号：`SLICE-004`
- 已执行验证：
  - 人工核对 `docs/novice-release-checklist.md`、`README.md`、`STATE.md`、`TRACKERS/TEST-MATRIX.md`
  - 人工核对 `dist/openclaw-win-x64-fat/` 与 `dist/openclaw-win-x64-fat/browsers/`
  - 人工核对 `build/build-windows.ps1`、`launchers/windows/*`、`launchers/unix/*`
- 结果结论：
  - 已确认 Windows fat 真实构建 smoke 早已完成，`TEST-004` 应以 `done / passed` 记录
  - 已确认当前主要未完成项已收敛为 `TEST-005` 纯净 Windows 首启验证，而不是 fat 包构建本身
  - `README.md` 已补充当前仓库实际支持的源码布局，并明确当前阶段仍属内部验收中

- 日期：2026-04-10
- 切片编号：`SLICE-006`
- 已执行验证：
  - 人工核对 `docs/novice-release-delivery/DOMAINS/windows-prepare-build-automation.md`
  - 人工对照 `build/build-windows.ps1`、`tools/environment-assets/windows/fetch-official-assets.ps1`、`tools/environment-assets/windows/prefetch-playwright-browsers.ps1`
  - 人工复核 prepare-build 自动化方案中的源码选择、缓存路径、完整性校验、Git 来源、网络参数与 pnpm 版本约束
- 结果结论：
  - 已确认原方案在“源码选择优先级”“Node.js 双缓存路径”“缓存完整性与失败恢复”上存在需要先修订的设计空洞
  - 已将计划修订为“manifest 优先选源、`downloads/` 为唯一权威缓存源、移除 `-PrepareOnly`、补齐 Git/代理/超时/重试/pnpm 版本约束”的实现基线
  - 当前可以在修订后的方案上进入 Slice A 实施，而不需要继续停留在抽象讨论

## 部分完成 / 跳过说明

- 原因：
  - 当前仓库没有稳定保留顶层 `openclaw/` 目录，真实构建 smoke 依赖的是 `openclaw-portable/openclaw` 布局
  - 产品页内 onboarding 仍依赖 OpenClaw 本体支持，无法在本仓库单独完结
- 处理结论：
  - 先推进本仓库可控的构建、文档与入口契约，保留兼容兜底脚本

## 风险

- 已知风险：
  - 真正的“页面内配置 API”仍依赖 OpenClaw 本体支持
  - 纯净 Windows 首启验证 (`TEST-005`) 尚未完成，当前还不能对外宣称“完全开箱即用已验收”
  - 若后续切换 OpenClaw 版本，仍需重新确认预取的 Playwright 浏览器资产与源码版本匹配
- 待确认事项：
  - macOS 正式发行物最终采用 `.app`、`.dmg` 还是其他 Finder 可双击形态

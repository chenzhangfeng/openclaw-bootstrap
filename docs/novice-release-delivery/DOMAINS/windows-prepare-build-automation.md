# Windows Prepare-Build Automation Domain

## 1. 决策摘要

- `build/build-windows.ps1` 默认改为“先 prepare，再 build”。
- 保留 `-SkipPrepare` 作为高级用户/离线复用场景的显式逃生口。
- 不为 `build/build-windows.ps1` 增加 `-PrepareOnly`；prepare-only 诉求统一由独立 prepare 脚本承担。
- 新增独立的 Windows prepare 脚本，专门负责把可缺失部件补齐到本地缓存。
- `tools/environment-assets/windows/downloads/` 成为 Node.js / MinGit 的唯一权威缓存路径；`build/cache/` 视为遗留路径并在后续实现中废弃。
- prepare 成功后必须把“本次准备所使用的源码路径与版本”写入 `manifest.local.json`；build 阶段默认优先消费该记录，而不是静默猜测多个候选源码目录。

## 2. 目标

- 让新机器上的开发者可以用尽量少的前置手工准备，重新构建一份可用的 Windows 便携包。
- 把“下载官方运行时”“准备 OpenClaw 源码”“预取 Playwright 浏览器”正式纳入工具链，而不是留给人工记忆。
- 保留本地缓存复用能力，避免每次发版都重复下载大体积资产。
- 保留高级用户的可控性，使其可以跳过 prepare，直接消费已准备好的本地资产。
- 提高构建可重复性，使同一次准备产出的源码版本、pnpm 版本、浏览器集合和缓存状态都可追溯。

## 3. 非目标

- 本轮不直接修改 OpenClaw 应用本体页面逻辑。
- 本轮不扩展 macOS / Linux 的同类 prepare 自动化。
- 本轮不承诺完成 CI/CD 发版流水线，只先把本地/手工发版路径闭环。
- 本轮不默认固化某个未经再次确认的上游 OpenClaw 仓库地址；在没有本地源码时，允许通过参数显式提供。

## 4. 当前问题

- `build/build-windows.ps1` 已能自动下载 Node.js、复制启动器、安装依赖并生成 `dist/`，但无法自动拉取 OpenClaw 源码。
- Playwright 浏览器预取能力已经存在于 `tools/environment-assets/windows/prefetch-playwright-browsers.ps1`，但没有被 build 默认编排进去。
- `fetch-official-assets.ps1` 与 `prefetch-playwright-browsers.ps1` 目前是“工具存在、用户自己串起来”的状态，不是正式构建契约的一部分。
- `build/build-windows.ps1` 当前同时使用 `tools/environment-assets/windows/downloads/` 和 `build/cache/` 作为 Node.js 缓存来源，存在双缓存源歧义。
- 当前源码解析策略只会取第一个命中的候选目录；prepare 自动 clone 落地后，若本地同时存在旧源码目录，容易静默选错。
- 当前缓存复用只看“文件是否存在”，没有完整性校验，也没有对中途失败后的半成品状态做恢复策略。
- 当前脚本没有显式锁定 pnpm 版本，也没有把网络代理、下载超时、重试和 Git 来源策略纳入正式计划。
- 当前 `fat` 包即使缺少浏览器缓存也能继续构建，只会告警；这对“小白正式包”目标过于宽松。

## 5. 目标用户流

### 5.1 默认一键构建流

适用人群：第一次接手仓库、希望一条命令产出 Windows 包的开发者。

示例命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\build\build-windows.ps1 `
  -Mode fat `
  -OpenClawRepo https://github.com/openclaw/openclaw.git `
  -OpenClawRef main
```

预期效果：

- 自动准备 Node.js / MinGit 缓存
- 自动准备 OpenClaw 源码
- 自动预取 Playwright 浏览器
- 自动执行 fat 构建并输出 `dist/openclaw-win-x64-fat/`

### 5.2 prepare-only 预热流

适用人群：想先把大体积资产拉齐，再反复本地 build 的开发者。

示例命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\environment-assets\windows\prepare-windows-build-assets.ps1 `
  -OpenClawRepo https://github.com/openclaw/openclaw.git `
  -OpenClawRef main `
  -BrowserSet all
```

预期效果：

- 只补齐缓存，不产出 `dist/`
- 后续可离线或半离线重复执行 build

### 5.3 高级跳过 prepare 流

适用人群：已经准备好源码与缓存，希望跳过网络步骤、直接构建的高级用户或 CI。

示例命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\build\build-windows.ps1 -Mode fat -SkipPrepare
```

预期效果：

- 不执行任何自动补齐逻辑
- 直接消费现有源码与缓存
- 若关键资产缺失，应尽快失败并给出可执行提示

## 6. 目标脚本接口

### 6.1 新增脚本

新增：

- `tools/environment-assets/windows/prepare-windows-build-assets.ps1`

建议首版参数：

- `-OpenClawPath`
  - 显式指定本地 OpenClaw 源码目录
- `-OpenClawRepo`
  - 当本地源码不存在或要求强制刷新时，用于克隆或刷新托管源码缓存
- `-OpenClawRef`
  - 默认 `main`
- `-BrowserSet`
  - `all` / `chromium` / `none`
- `-PnpmVersion`
  - 锁定 prepare 与 build 统一使用的 pnpm 版本
- `-Force`
  - 强制重新下载、重新拉取或重新预取
- `-SkipOfficialAssets`
  - 跳过 Node.js / MinGit 官方资产准备
- `-SkipBrowserPrefetch`
  - 跳过浏览器预取
- `-ProxyUri`
  - 显式代理配置；若未提供，则自动继承 `$env:HTTPS_PROXY` / `$env:HTTP_PROXY`
- `-TimeoutSec`
  - 单次网络操作超时，建议默认 `300`
- `-RetryCount`
  - 网络失败后的有限重试次数，建议默认 `3`
- `-DryRun`
  - 只打印计划执行的动作，不实际修改本地环境

### 6.2 修改现有脚本

修改：

- `build/build-windows.ps1`

建议新增参数：

- `-SkipPrepare`
  - 高级用户显式跳过 prepare
- `-OpenClawRepo`
  - 透传给 prepare
- `-OpenClawRef`
  - 透传给 prepare
- `-BrowserSet`
  - `fat` 默认 `all`，`slim` 默认 `none`
- `-PnpmVersion`
  - 透传给 prepare，并用于 build 阶段依赖安装
- `-ProxyUri`
  - 透传给 prepare
- `-TimeoutSec`
  - 透传给 prepare
- `-RetryCount`
  - 透传给 prepare
- `-AllowMissingBrowsers`
  - 仅为高级场景保留；若未显式提供，`fat` 构建缺少浏览器缓存时应失败

## 7. 目录与缓存契约

建议把 Windows 可复用缓存统一收敛到：

```text
tools/environment-assets/windows/
├─ downloads/
│  ├─ node-v<version>-win-x64.zip
│  └─ MinGit-<version>-64-bit.zip
├─ playwright-browsers/
├─ source-cache/
│  └─ openclaw/
├─ manifest.local.json
├─ fetch-official-assets.ps1
├─ prefetch-playwright-browsers.ps1
├─ prepare-windows-build-assets.ps1
└─ shared-functions.ps1
```

关键约束：

- `downloads/` 是 Node.js / MinGit 的唯一权威缓存目录
- `build/cache/` 属于遗留路径，只为过渡期兼容保留，实施中应废弃
- `playwright-browsers/` 继续存放与真实源码版本匹配的浏览器缓存
- `source-cache/openclaw/` 用于托管由 prepare 自动拉取的源码副本
- `manifest.local.json` 记录最近一次成功 prepare 的源码路径、版本、浏览器状态和缓存校验信息
- 仍然兼容仓库根 `openclaw/` 与 `openclaw-portable/openclaw/` 两种布局

源码解析优先级建议为：

1. 显式 `-OpenClawPath`
2. `manifest.local.json` 中最近一次成功 prepare 的 `source.selectedPath`
3. 仓库根 `openclaw/`
4. `openclaw-portable/openclaw/`
5. `tools/environment-assets/windows/source-cache/openclaw/`
6. 若以上都不存在，则要求用户提供 `-OpenClawRepo`

附加规则：

- 若命中第 2 项，则 build 必须明确打印“Using prepared source from manifest”
- 若在没有显式 `-OpenClawPath` 且没有 manifest 指示的情况下同时发现多个候选源码目录，不得静默取第一个命中；应直接失败并提示用户显式指定
- build 不得在多个候选目录并存时默默忽略 prepare 刚写入的源码缓存

## 8. prepare 阶段职责

`prepare-windows-build-assets.ps1` 只负责补齐材料，不负责产出分发目录。

建议职责如下：

1. 解析参数并确定目标模式
2. 获取 prepare 锁，避免同一工作目录下并发写入缓存
3. 调用或复用 `fetch-official-assets.ps1`，确保 Node.js / MinGit 已缓存
4. 复用缓存前先做完整性校验；若校验失败，则删除损坏文件并重新下载
5. 解析 OpenClaw 源码来源
6. 若使用 Git 模式，则优先使用系统 Git；若系统 Git 不可用，则临时解压缓存中的 MinGit 作为运行时 Git
7. Git 拉取时先在临时目录执行 clone / fetch / checkout / reset，成功后再原子切换到 `source-cache/openclaw/`
8. 若需要浏览器，则调用或复用 `prefetch-playwright-browsers.ps1`
9. 统一写入 `manifest.local.json`
10. 释放锁并输出 prepare 摘要

不建议在 prepare 阶段直接创建 `dist/`，这样才能保持 prepare 可复用、可重复运行、可独立调试。

## 9. build 阶段集成方案

`build/build-windows.ps1` 的新主流程建议为：

1. 解析 `Mode`、源码参数与 prepare 相关参数
2. 若未指定 `-SkipPrepare`，则先调用 `prepare-windows-build-assets.ps1`
3. 按新的源码优先级解析最终要使用的源码目录
4. 若未显式指定源码且存在多个候选目录冲突，则 fail-fast 并要求用户显式指定
5. 复用现有 build 流程，但做如下收敛：
   - 仅从 `tools/environment-assets/windows/downloads/` 复用 Node.js
   - 不再把 `build/cache/` 作为正式缓存源
   - 安装依赖时使用固定 `pnpm@<version>`
   - `fat` 构建默认要求浏览器缓存可用
6. 生成更明确的构建摘要，显示：
   - 使用的源码路径
   - 源码 repo / ref / commit
   - 浏览器缓存状态
   - pnpm 版本
   - 是否使用了 `-SkipPrepare`
   - 构建机 PowerShell 版本与脚本提交版本

## 10. 失败策略

为了让默认 build 更接近“小白正式包”目标，建议按下面策略收紧：

- `fat` 模式下：
  - 缺少源码：直接失败
  - 缺少 Node.js 官方资产且自动准备失败：直接失败
  - 缺少浏览器缓存且未显式允许缺失：直接失败
  - 缺少 MinGit：允许继续，但仅限系统 Git 可用；否则失败并提示先准备 Git 运行时
- `slim` 模式下：
  - 允许跳过浏览器预取
  - 仍要求源码可用
- 进入 `-SkipPrepare` 时：
  - 若 manifest、源码目录或权威缓存缺失，不得自动回退到模糊猜测；应直接失败

错误信息必须带可执行提示，例如：

- “请提供 `-OpenClawRepo` 或 `-OpenClawPath`”
- “检测到多个源码候选目录，请显式传入 `-OpenClawPath`”
- “请先联网执行 prepare，或显式使用 `-SkipPrepare` 消费既有缓存”
- “系统 Git 不可用，且未检测到可用的 MinGit 缓存；请先执行官方资产准备”
- “若你确实要构建不含浏览器的非正式 fat 包，请显式传入 `-AllowMissingBrowsers`”
- “下载失败时请检查网络代理配置，或设置 `-ProxyUri` / `$env:HTTPS_PROXY`”

恢复策略建议为：

- 下载统一先写到临时文件，再原子替换正式缓存文件
- Git 拉取统一先写到临时目录，再切换到正式目录
- `manifest.local.json` 记录 `lastPrepareResult = partial | success`
- 若发现上次 prepare 处于 `partial`，下一次执行时默认强制重做受影响步骤

## 11. manifest 与可追溯性

建议扩展 `manifest.local.json`，至少记录：

- `schemaVersion`
- `generatedAt`
- `lastPrepareResult`
- `node.version`
- `node.file`
- `node.sha256`
- `node.fileSize`
- `minGit.releaseTag`
- `minGit.file`
- `minGit.sha256`
- `pnpm.version`
- `source.mode`
- `source.repo`
- `source.ref`
- `source.commit`
- `source.selectedPath`
- `source.selectionSource`
- `playwright.browserSet`
- `playwright.status`
- `playwright.path`
- `network.proxySource`

建议 build 成功后再在 `dist/` 内写一份只读构建摘要，例如：

- `dist/openclaw-win-x64-fat/build-manifest.json`

建议其中额外记录：

- `builderScript.commit`
- `buildDuration`
- `platform.os`
- `platform.powershellVersion`

这样后续出现“包是用哪个源码版本打出来的”时，不需要回忆聊天记录或翻本地命令历史。

## 12. 实施切片

### Slice A：接口、共享函数与缓存权威源落地

- 新建 `prepare-windows-build-assets.ps1`
- 新建 `shared-functions.ps1`
- 提取共享的 `Resolve-OpenClawSourceDir`、`Ensure-Directory` 等函数
- 确定 `source-cache/` 目录结构
- 明确 `downloads/` 为唯一权威缓存源
- 扩展 `manifest.local.json` schema

### Slice B：prepare 编排闭环

- 复用 `fetch-official-assets.ps1`
- 增加缓存完整性校验
- 增加系统 Git / 临时 MinGit 双来源策略
- 增加源码 clone / update 能力
- 增加临时目录切换与 `partial` 恢复策略
- 复用 `prefetch-playwright-browsers.ps1`
- 跑通 prepare-only

### Slice C：build 默认接 prepare

- `build/build-windows.ps1` 增加 `-SkipPrepare`
- `build/build-windows.ps1` 增加源码冲突检测
- build 默认自动调用 prepare
- 移除 `build/cache/` 作为正式 Node.js 缓存源

### Slice D：严格化、锁版本与报错收敛

- `fat` 模式缺浏览器改为默认失败
- 增加 `-AllowMissingBrowsers`
- 锁定 pnpm 版本
- 补充代理、超时、重试和 Git 缺失报错
- 输出更友好的构建摘要与 `build-manifest.json`

### Slice E：文档与验证回填

- 更新 `README.md`
- 更新 `tools/environment-assets/windows/README.md`
- 更新 `TRACKERS/TEST-MATRIX.md`
- 回写 checkpoint / acceptance

## 13. 验证增补建议

建议为后续实现新增至少 5 个验证单元：

- `TEST-010`
  - 纯净仓库、无本地源码时，prepare 能基于 `-OpenClawRepo` 拉起托管源码缓存
  - 建议在 Slice B 后验证
- `TEST-011`
  - `build/build-windows.ps1 -Mode fat` 默认会自动触发 prepare
  - 建议在 Slice C 后验证
- `TEST-012`
  - `-SkipPrepare` 在缓存与源码已准备好的前提下仍可成功构建
  - 建议在 Slice C 后验证
- `TEST-013`
  - `fat` 模式缺少浏览器缓存时会 fail-fast，而不是只告警继续
  - 建议在 Slice D 后验证
- `TEST-014`
  - `manifest.local.json` 与 `dist/*/build-manifest.json` 能记录真实源码版本与浏览器状态
  - 建议在 Slice D 后验证

## 14. 风险与未决项

- 风险
  - 若上游 OpenClaw 仓库地址和默认分支不稳定，直接硬编码默认值会降低可靠性
  - 浏览器全量 `all` 与 `chromium` 之间仍有体积与兼容性的权衡
  - 托管源码缓存若长期不清理，磁盘占用会快速增大
  - 当前方案默认不保证同一工作目录下的并发构建安全；若不实现锁文件，容易发生缓存竞争写入
- 未决项
  - 是否要为 `prepare` 增加 `-RepoCommit` 一类更强约束参数
  - 是否要让 `build/build-windows.ps1` 在 `fat` 模式默认选择 `all` 还是 `chromium`
  - 是否要在后续把 Windows prepare 能力进一步复用到 CI
  - 是否需要为 `BrowserSet` 选择建立体积/功能数据基线

## 15. 推荐下一步

- 先实现 `tools/environment-assets/windows/prepare-windows-build-assets.ps1`
- 同步落地 `shared-functions.ps1` 与 manifest schema
- 再把 `build/build-windows.ps1` 接到默认 auto-prepare，并废弃 `build/cache/`
- 最后补 `README.md`、验证矩阵和一轮 fresh-workspace smoke

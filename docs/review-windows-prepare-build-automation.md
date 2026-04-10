# windows-prepare-build-automation.md 方案审查报告

> 审查日期：2026-04-10
> 审查对象：`docs/novice-release-delivery/DOMAINS/windows-prepare-build-automation.md`
> 交叉参照：`README.md`、`build/build-windows.ps1`、`tools/environment-assets/windows/fetch-official-assets.ps1`、`tools/environment-assets/windows/prefetch-playwright-browsers.ps1`、`STATE.md`、`TRACKERS/TEST-MATRIX.md`

---

## 总体评价

方案整体质量较高，问题定义精准、用户流分级合理、切片拆分可执行性强。以下按"需要补充 → 需要纠正 → 建议优化"三个维度给出具体分析。

### 评分总览

| 维度 | 评价 | 说明 |
|------|------|------|
| 问题定义 | ⭐⭐⭐⭐⭐ | 精准识别了现有工具链"工具存在、用户自己串"的核心痛点 |
| 用户流设计 | ⭐⭐⭐⭐⭐ | 三级用户流划分清晰，示例命令可直接执行 |
| 接口设计 | ⭐⭐⭐⭐ | 参数命名合理，但 `-PrepareOnly` 的归属可讨论 |
| 缓存策略 | ⭐⭐⭐ | 缺少完整性校验和并发保护 |
| 失败策略 | ⭐⭐⭐⭐ | 已覆盖主要失败路径，但缺少中途失败恢复 |
| 可追溯性 | ⭐⭐⭐⭐ | manifest 设计好，建议补 schema 版本和更多构建元信息 |
| 实施可行性 | ⭐⭐⭐⭐⭐ | 5 个切片粒度合适，依赖关系清晰 |
| 与现有代码的对齐 | ⭐⭐⭐ | 存在函数重复、双缓存路径等需要收敛的遗留问题 |

---

## 一、需要纠正的问题（3 项）

### 纠正-1：源码解析优先级存在歧义风险

**位置**：方案 §7 源码解析优先级

**原文**：

```
1. 显式 -OpenClawPath
2. 仓库根 openclaw/
3. openclaw-portable/openclaw/
4. tools/environment-assets/windows/source-cache/openclaw/
5. 若以上都不存在，则要求用户提供 -OpenClawRepo
```

**问题**：`source-cache/openclaw/` 排在第 4 位，低于仓库根 `openclaw/`。但在 prepare 自动 clone 场景下，源码是被放到 `source-cache/openclaw/` 的。如果用户仓库根同时还存在一个**旧的、手动放置的** `openclaw/` 目录，就会静默使用旧源码构建，而用户以为 prepare 拉取的才是生效的。

**建议**：

- 方案 A：在 prepare 成功后将实际使用的源码路径写入 `manifest.local.json`，build 阶段以 manifest 中记录的路径为最高优先级（仅次于显式 `-OpenClawPath`）
- 方案 B：在检测到多个候选源码目录同时存在时，输出明确警告让用户确认，而不是静默取第一个命中的

---

### 纠正-2：`-PrepareOnly` 不应归属于 build 脚本

**位置**：方案 §6.2、§9 步骤 3、§12 Slice C

**原文**：

```
- `-PrepareOnly`
  - 只做 prepare，不进入 build
```

以及 §9：

```
3. 若指定 -PrepareOnly，则在 prepare 成功后退出
```

**问题**：从职责分离的角度，如果用户只想 prepare 不 build，那直接调用 `prepare-windows-build-assets.ps1` 就好了——这不应该是 build 脚本的职责。`-PrepareOnly` 让 build 脚本承担了一个"不 build"的职能，概念矛盾。

**建议**：

- 去掉 `build-windows.ps1` 的 `-PrepareOnly` 参数
- 在 §5.2 用户流和文档中引导用户直接调用 prepare 脚本来做 prepare-only 操作
- 保持 build 脚本的单一职责：它要么 build（可能先 prepare），要么跳过 prepare 直接 build
- 从 §12 Slice C 中移除相关条目

---

### 纠正-3：Node.js 双缓存路径冲突

**位置**：方案 §9 步骤 5

**原文**：

```
5. 复用现有 build 流程：
   - 下载或复用 Node.js
```

**问题**：现有 `build-windows.ps1`（L174-176）维护了一个独立的 `build/cache/` 路径用于缓存 Node.js：

```powershell
$buildCacheDir = Join-Path $RepoRoot "build\cache"
$buildCacheNodeArchive = Join-Path $buildCacheDir "$NodeZipName.zip"
```

prepare 引入后，`tools/environment-assets/windows/downloads/` 变成了正式的官方缓存路径。两套路径同时存在会产生混淆：哪个是权威源？文件不一致时以谁为准？

**建议**：

- 在方案中明确：统一 Node.js 缓存路径到 `tools/environment-assets/windows/downloads/`
- 标注 `build/cache/` 为遗留路径，在 Slice C 中将其废弃
- §9 步骤 5 修改为"从 `tools/environment-assets/windows/downloads/` 复用 Node.js（prepare 已确保其就绪）"

---

## 二、需要补充的内容（6 项）

### 补充-1：缓存完整性校验机制

**现状**：方案只说了"复用本地缓存"和 `-Force` 重新下载，但没有提到文件完整性验证。

**风险**：`downloads/` 下的 zip 文件可能因网络中断而成为损坏的半成品。现有 `fetch-official-assets.ps1` 直接 `Invoke-WebRequest` 下载，没有任何 checksum 校验。半截 zip 文件仍然存在于磁盘上，下次执行时会被 `Test-Path` 判定为"已缓存"而跳过下载。

**建议**：

- 在 `manifest.local.json` 中记录 `sha256` 或 `expectedSize`
- prepare 阶段复用缓存时先做校验，若失败则重新下载
- 在 §8 职责列表和 §11 manifest 字段中补充相关条目

---

### 补充-2：Git 可用性的隐含前提

**现状**：方案 §8 的 prepare 职责第 4 条写到"若使用 Git 模式，则在 `source-cache/openclaw/` 执行 clone / fetch / checkout / reset"。但这意味着 prepare 脚本自身需要一个可用的 Git。

**矛盾**：

- 当前项目的 MinGit 是作为**发行物嵌入资产**下载的，不是开发环境工具
- 在"新机器"场景下，系统 `PATH` 可能没有 Git
- 如果用户本机连 Git 都没有，那"纯净仓库"这个概念本身就存在矛盾——没有 Git 怎么获取仓库本体？

**建议**：

- 在方案中明确 prepare 阶段 Git 的来源策略：
  - **选项 A**：要求系统已安装 Git（记录为 prepare 的显式前置条件）
  - **选项 B**：临时解压已缓存的 MinGit 来使用（需要在 `fetch-official-assets.ps1` 之后、Git clone 之前插入"临时解压 MinGit 到运行时"的步骤）
- 在 §10 失败策略中增加"系统无 Git 且 MinGit 未缓存"的错误提示

---

### 补充-3：网络代理 / 镜像配置

**现状**：方案完全没有提及网络环境适配。

**风险**：

- 现有脚本硬编码了 `https://registry.npmmirror.com` 作为 npm 镜像
- `fetch-official-assets.ps1` 直接访问 `api.github.com` 和 `nodejs.org`
- 在中国大陆环境下，GitHub API 和 Node.js 官方下载可能因网络问题导致 prepare 卡住或超时

**建议**：

- 在 §6.1 prepare 脚本参数中增加 `-ProxyUri`（可选）
- 或在 §8 prepare 职责中注明"自动继承 `$env:HTTPS_PROXY`"
- 在 §10 失败策略的错误信息中增加"如果下载失败，请检查网络代理配置或设置 `$env:HTTPS_PROXY`"

---

### 补充-4：pnpm 版本锁定

**现状**：现有 `build-windows.ps1`（L260）和 `prefetch-playwright-browsers.ps1`（L96）都用 `npm install -g pnpm` 安装——**没有指定版本号**。方案 §11 的 manifest 中记录了 `node.version` 和 `minGit.releaseTag`，但没有 `pnpm.version`。

**风险**：不同版本的 pnpm store 格式可能不兼容，导致缓存复用失败或构建不可重复。

**建议**：

- 在 §11 manifest 字段列表中增加 `pnpm.version`
- 构建脚本安装时使用 `npm install -g pnpm@<version>` 进行版本锁定
- 建议在项目配置中维护一个 pnpm 目标版本常量

---

### 补充-5：超时与重试策略

**现状**：`Invoke-WebRequest` 在大文件下载时默认没有超时控制。如果网络波动，脚本可能无限等待。

**建议**：

- 为 prepare 阶段的网络操作加入 `-TimeoutSec`（建议 300 秒）
- 失败后有限重试（建议最多 3 次，指数退避）
- 在 §8 prepare 职责或 §10 失败策略中补充说明

---

### 补充-6：`Resolve-OpenClawSourceDir` 共享函数提取

**现状**：当前 `build-windows.ps1`（L79-108）和 `prefetch-playwright-browsers.ps1`（L18-49）各自独立定义了一份几乎相同的 `Resolve-OpenClawSourceDir` 函数。方案引入 `prepare-windows-build-assets.ps1` 后，这个函数的使用场景将增加到 3 处。

**建议**：

- 在 §12 实施切片 Slice A 中增加一个子任务："提取共享工具函数到 `tools/environment-assets/windows/shared-functions.ps1`"
- 三个脚本通过 `. (dot-source)` 引用共享函数
- 同时提取的候选函数还包括 `Ensure-Directory`（`fetch-official-assets.ps1` L15-24）

---

## 三、优化建议（7 项）

### 优化-1：`manifest.local.json` 增加 schema 版本

方案 §11 扩展了 manifest 字段，但没有加 `schemaVersion`。随着后续迭代，旧 manifest 和新脚本之间可能出现兼容问题。

**建议**：在 manifest 最顶层加 `"schemaVersion": 1`，脚本读取时做版本检查。

---

### 优化-2：`build-manifest.json` 增加更多构建元信息

方案只列了源码版本和浏览器状态。建议再加上：

- `builderScript.commit`：build 脚本自身所在的 Git commit（方便追溯"用哪个版本的打包工具打的"）
- `buildDuration`：构建耗时
- `platform.os`：构建机系统版本（如 `Windows 10 22H2`）
- `platform.powershellVersion`：PowerShell 版本

---

### 优化-3：验证 TEST 与 Slice 对齐

方案 §13 建议了 TEST-010 ~ TEST-014，但没有明确标注它们分别应该在哪个 Slice（A/B/C/D/E）完成后执行。

**建议对齐**：

| TEST | 建议在哪个 Slice 后验证 |
|------|------------------------|
| TEST-010 | Slice B（prepare 编排闭环后） |
| TEST-011 | Slice C（build 默认接 prepare 后） |
| TEST-012 | Slice C |
| TEST-013 | Slice D（严格化后） |
| TEST-014 | Slice D |

---

### 优化-4：考虑 `--dry-run` 模式

对于首次接手仓库的开发者，先看看 prepare 打算做什么比直接执行更安全。

**建议**：为 `prepare-windows-build-assets.ps1` 加一个 `-DryRun` 参数，只打印将要执行的操作列表但不实际执行。示例输出：

```
[DRY-RUN] Would download Node.js v22.22.1 to downloads/node-v22.22.1-win-x64.zip
[DRY-RUN] Would download MinGit latest to downloads/MinGit-*.zip
[DRY-RUN] Would clone https://github.com/openclaw/openclaw.git (ref: main) to source-cache/openclaw/
[DRY-RUN] Would prefetch Playwright browsers (set: all) to playwright-browsers/
```

---

### 优化-5：中途失败恢复策略

当 prepare 在中途失败（比如 Node.js 下载成功但 Git clone 超时），当前方案没有说明如何恢复。下次重新执行时：

- Node.js 已经缓存，会被跳过 — ✅ 正确
- Git clone 可能留下不完整的 `source-cache/openclaw/` — ❌ 不完整目录可能被误认为已存在

**建议**：

- 方案 A：在 `manifest.local.json` 中引入 `lastPrepareResult: "partial"` / `"success"` 状态标记，下次执行时如果发现 `partial` 则强制重做
- 方案 B：Git 操作先 clone 到临时目录（如 `source-cache/.openclaw-wip/`），成功后再 rename 到正式路径

---

### 优化-6：`BrowserSet` 默认值未决项补充

方案 §14 的未决项中列了"是否要让 `fat` 默认选择 `all` 还是 `chromium`"，但没有给出决策所需的数据参考。

**建议补充决策依据**：

- 当前 `fat` 包 3.32GB（含全量浏览器），其中 Playwright 浏览器占比约多少？
- 切换到 `chromium` only 后预计可减到什么量级？
- OpenClaw 在功能上是否真实依赖非 Chromium 浏览器？

这些数据点应在 §14 中列出，以便后续决策时有据可查。

---

### 优化-7：并发安全标注

如果两个终端同时执行 `build-windows.ps1 -Mode fat`，prepare 阶段可能并发写同一个 `source-cache/openclaw/` 的 Git 仓库，或并发下载同一个 zip 到 `downloads/`。

**建议**：

- 在 §14 风险中增加一条："当前方案不保证同一工作目录下的并发构建安全"
- 或在 prepare 执行开始时使用简单的文件锁（如 `.prepare.lock`），检测到锁文件存在时提示用户

---

## 四、结论

| 类别 | 数量 | 建议处理时机 |
|------|------|-------------|
| 需要纠正 | 3 项 | 进入 Slice A 之前合入方案文档 |
| 需要补充 | 6 项 | 进入 Slice A 之前合入方案文档 |
| 建议优化 | 7 项 | 可在对应 Slice 实施时逐步落地 |

**总体结论**：方案可以作为实施基线。建议在进入 Slice A 之前，优先处理 3 个纠正项和 6 个补充项；7 个优化项可在对应切片实施时逐步纳入。

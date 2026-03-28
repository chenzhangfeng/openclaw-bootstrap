# macOS Distribution Domain

## 1. 目标

- 为 macOS 小白用户定义正式发行物目标形态。
- 让当前仓库从“shell-first 技术流”过渡到“Finder 可直接启动”的产品流。
- 明确当前阶段只先完成目标形态与迁移任务拆解，不在本仓库内承诺一次性完成 `.app` / `.dmg` 成品。

## 2. 范围

- in scope
  - macOS 正式发行物目标形态
  - 当前脚本式分发的定位
  - 从 shell-first 过渡到 app-first 的任务拆解
  - Apple Silicon / Intel 的发版策略
- out of scope
  - OpenClaw 本体页面内模型配置实现
  - Apple Developer 签名、notarization 的真实账号操作
  - 非 macOS 平台的具体实现细节
- 边界
  - 本领域只定义 macOS 分发契约和过渡任务，不替代 Windows fat 包闭环与真实机器 smoke

## 3. 依赖

- 上游依赖
  - OpenClaw 应用源码可被稳定打包
  - Windows fat 包闭环经验可复用到 macOS 发行物结构
- 外部依赖
  - Apple Silicon / Intel 真机验证
  - 可能需要签名与 Gatekeeper 处理策略

## 4. 当前结论

- 正式目标形态：
  - 首选 `.app`
  - 分发层首选 `.dmg`
- 当前仓库现状：
  - `build/build-unix.sh` 只能生成目录级产物
  - `launchers/unix/*.sh` 仍要求用户接触终端、`chmod`、shell 脚本
  - 这条链路目前只能视为过渡方案，不能当作 macOS 小白正式发行物

## 5. 迁移任务

1. 保留当前 `build/build-unix.sh` 作为开发者构建入口，但不再把它直接包装成小白终端用户流程
2. 为 macOS 正式包新增 app-first 包装层
3. 区分 `darwin-arm64` 与 `darwin-x64` 两类发行物
4. 为首次打开的 Gatekeeper 提示准备用户文案和操作说明
5. 将“先启动，后在页面里配置 API；脚本仅兼容兜底”的契约同步到 macOS 启动器与文档
6. 在具备条件时，再决定是否进入签名 / notarization 线

## 6. 当前状态

- 已完成
  - 目标形态已定义为 `.app` / `.dmg`
  - 过渡方案与正式目标之间的差距已写清
  - 迁移任务已拆为 6 条可执行项
- 进行中
  - 入口契约文案已同步到 Unix 启动器
- 阻塞项
  - 缺少真正的 app 包装层实现
  - 缺少真实 macOS 机器回归验证
- 下一步最小动作
  - 当 Windows fat 包 smoke 条件具备后，复用其资产清单方法，为 macOS app-first 包装层起草实施切片

## 7. 风险与未决项

- 风险
  - 若没有 `.app` / `.dmg`，macOS 小白体验无法真正达标
  - 若没有签名策略，首次打开体验仍会受系统安全提示影响
- 临时兼容策略
  - 当前继续保留 `launchers/unix/*.sh` 作为技术向过渡入口
  - 文案上明确其不是最终小白正式包形态

## 8. 验证口径

- 最低可交付标准
  - 文档中已明确 macOS 正式目标与当前过渡状态
  - 迁移任务已可供后续切片执行
- 必做验证动作
  - 人工核对 `README.md`、本领域文档、`launchers/unix/*` 的对外口径一致
- 回归关注点
  - 不要让 README 把 shell-first 过渡流误写成最终小白正式流程

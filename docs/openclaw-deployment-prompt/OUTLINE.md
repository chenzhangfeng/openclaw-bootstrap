# OpenClaw Deployment Prompt Outline

## 1. Repository Fact Collection
- [x] 1.1 确认当前仓库边界与真实文件清单
  - 验证引用：`TEST-001`
  - 验证动作：`git ls-files`、`rg --files`
- [ ] 1.2 提取 OpenClaw 应用启动入口、依赖定义、配置入口、容器化现状
  - 验证引用：`TEST-002`、`TEST-003`
  - 验证动作：检查 `README*`、`pyproject.toml`、`requirements*.txt`、`Dockerfile`、`compose*`、`scripts/`、`docs/`
  - 依赖：1.1
  - 细节：`DOMAINS/repository-facts.md`
- [ ] 1.3 形成 `Repository Findings / Deployment Decision / Missing Information` 初稿
  - 验证引用：`TEST-004`
  - 验证动作：人工核对 findings 仅引用仓库内已证实文件
  - 依赖：1.2

## 2. Prompt Decomposition
- [x] 2.1 将 `openclaw_create_prompt.md` 拆成执行阶段、交付物集合和硬性约束
  - 验证引用：`TEST-005`
  - 验证动作：人工核对 `OUTLINE.md` 与 `DOMAINS/prompt-breakdown.md`
- [x] 2.2 把部署资产拆成同步交付单元
  - 验证引用：`TEST-006`
  - 验证动作：确认安装、升级、卸载、Compose、Dockerfile、`.env.example`、文档均有落点
  - 依赖：2.1
  - 细节：`DOMAINS/prompt-breakdown.md`、`DOMAINS/output-contract.md`
- [x] 2.3 标记必须依赖真实源码的决策点与可提前准备的通用脚手架
  - 验证引用：`TEST-007`
  - 验证动作：人工核对阻塞点与可并行项分离清楚
  - 依赖：1.2、2.1
  - 细节：`DOMAINS/repository-facts.md`、`DOMAINS/prompt-breakdown.md`、`DOMAINS/output-contract.md`

## 3. Deployment Asset Execution
- [ ] 3.1 基于真实源码确定部署方式与健康检查依据
  - 验证引用：`TEST-008`
  - 验证动作：人工核对 `Deployment Decision` 仅基于已证实入口
  - 依赖：1.3、2.3
- [ ] 3.2 生成部署资产代码
  - 验证引用：`TEST-009`
  - 验证动作：人工核对产物集合完整且变量一致
  - 依赖：3.1
- [ ] 3.3 生成使用说明、验证说明、兼容性与安全说明
  - 验证引用：`TEST-010`
  - 验证动作：人工核对输出顺序符合 prompt 合同
  - 依赖：3.2

## 4. Validation And Handoff
- [x] 4.1 建立恢复文档与验证矩阵
  - 验证引用：`TEST-011`
  - 验证动作：确认 `STATE.md`、`ACCEPTANCE.md`、`TRACKERS/TEST-MATRIX.md`、`CHECKPOINTS/` 已创建
- [x] 4.2 写稳定 checkpoint 并持续推进下一步最小动作
  - 验证引用：`TEST-012`
  - 验证动作：检查 checkpoint 记录 git 状态、验证债和下一步最小动作
  - 依赖：4.1
- [ ] 4.3 完成最终总结与后续 TODO
  - 验证引用：`TEST-013`
  - 验证动作：人工核对 `FINAL.md`、`TODO.md` 与 `STATE.md` 一致
  - 依赖：3.3

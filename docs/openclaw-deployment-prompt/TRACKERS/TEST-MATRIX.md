# OpenClaw Deployment Prompt Test Matrix

## 使用说明

- 一行一个验证单元。
- 本表只表示验证推进，不表示实现推进；实现状态以 `OUTLINE.md` 为准。
- 当前仓库缺少真实 OpenClaw 应用源码，因此与运行事实相关的验证项会先登记为验证债。

| ID | 领域 | 层级 | 目标 | 覆盖对象 | 关联实现 | 状态 | 结果 | 验证方式 | 证据 | 文件位置 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TEST-001 | repository-facts | smoke | 确认当前仓库边界与已跟踪文件清单 | 当前仓库 | `1.1` | done | passed | `git ls-files` + `rg --files` | 已确认仅有 `.gitignore`、`AGENTS.md`、`openclaw_create_prompt.md` 为 git 跟踪文件 | `openclaw_create_prompt.md` | `.agnet/skills/**` 存在但未纳入 git 跟踪 |
| TEST-002 | repository-facts | manual | 识别真实启动入口与依赖定义 | OpenClaw 应用源码 | `1.2` | blocked | not_run | 检查 `README*`、`pyproject.toml`、`requirements*.txt`、启动脚本 | 当前仓库缺少这些文件 | `DOMAINS/repository-facts.md` | 验证债；需真实应用仓库 |
| TEST-003 | repository-facts | manual | 识别已有容器化配置、镜像策略与健康检查依据 | 部署资产 | `1.2` | blocked | not_run | 检查 `Dockerfile`、`compose*`、`scripts/`、`docs/` | 当前仓库缺少这些文件 | `DOMAINS/repository-facts.md` | 验证债；需真实应用仓库 |
| TEST-004 | findings-contract | review | 确保 findings/decision/missing-information 只引用已证实事实 | 最终输出合同 | `1.3` | todo | not_run | 人工审阅文档引用链 | 待执行 | `OUTLINE.md` | 依赖 `1.2` |
| TEST-005 | prompt-breakdown | review | 确认 prompt 拆解覆盖阶段、交付物和硬约束 | `openclaw_create_prompt.md` | `2.1` | done | passed | 人工对照 prompt 与拆解文档 | 已完成拆解骨架与后续落点设计 | `DOMAINS/prompt-breakdown.md` | 需继续细化资产级切片 |
| TEST-006 | prompt-breakdown | review | 确认所有部署资产均有对应实现落点 | 资产清单 | `2.2` | done | passed | 人工核对资产矩阵 | 已覆盖 install/upgrade/uninstall/compose/Dockerfile/.env/docs 七类资产 | `DOMAINS/prompt-breakdown.md` | 与 `DOMAINS/output-contract.md` 对齐 |
| TEST-007 | prompt-breakdown | review | 区分必须等待源码确认的决策点与可提前准备项 | 执行边界 | `2.3` | done | passed | 人工核对阻塞映射 | 已列出真实入口、端口、健康检查、secrets、目录、镜像策略等待确认项 | `DOMAINS/repository-facts.md` | 输出合同和可提前脚手架已分离 |
| TEST-008 | deployment-decision | review | 基于真实源码确定部署方式和健康检查依据 | `Deployment Decision` | `3.1` | blocked | not_run | 人工审阅事实链 | 缺少应用源码 | `DOMAINS/repository-facts.md` | 验证债；需真实应用仓库 |
| TEST-009 | deployment-assets | review | 确认部署代码资产完整且跨文件一致 | 代码产物集合 | `3.2` | todo | not_run | 人工审阅代码一致性 | 待执行 | `OUTLINE.md` | |
| TEST-010 | deployment-docs | review | 确认最终输出顺序与说明完整 | 文档产物 | `3.3` | todo | not_run | 人工核对 prompt 合同 | 待执行 | `OUTLINE.md` | |
| TEST-011 | task-driven-dev | smoke | 确认任务恢复文档与验证矩阵已创建 | `docs/openclaw-deployment-prompt/` | `4.1` | done | passed | 检查文档文件是否存在 | 本次新增任务容器文件 | `docs/openclaw-deployment-prompt/` | |
| TEST-012 | task-driven-dev | review | 确认 checkpoint 记录 git 状态、验证债和下一步最小动作 | checkpoint | `4.2` | done | passed | 人工审阅 checkpoint | 已确认 checkpoint 记录 git 状态、验证债、风险与恢复动作 | `CHECKPOINTS/2026-03-15-01-scaffold-and-breakdown.md` | checkpoint 创建时 git 提交尚未执行 |
| TEST-013 | task-driven-dev | review | 确认最终总结与 TODO 同步到状态文件 | `FINAL.md` / `TODO.md` | `4.3` | todo | not_run | 人工审阅文档一致性 | 待执行 | `FINAL.md` | |

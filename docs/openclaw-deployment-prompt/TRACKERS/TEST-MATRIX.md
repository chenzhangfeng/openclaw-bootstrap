# OpenClaw Deployment Prompt Test Matrix

## 使用说明

- 一行一个验证单元。
- 本表只表示验证推进，不表示实现推进；实现状态以 `OUTLINE.md` 为准。
- 当前仓库缺少真实 OpenClaw 应用源码，因此与运行事实相关的验证项会先登记为验证债。

| ID | 领域 | 层级 | 目标 | 覆盖对象 | 关联实现 | 状态 | 结果 | 验证方式 | 证据 | 文件位置 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TEST-001 | repository-facts | smoke | 确认当前仓库边界与已跟踪文件清单 | 当前仓库 | `1.1` | done | passed | `git ls-files` + `rg --files` | 已确认仅有 `.gitignore`、`AGENTS.md`、`openclaw_create_prompt.md` 为 git 跟踪文件 | `openclaw_create_prompt.md` | `.agnet/skills/**` 存在但未纳入 git 跟踪 |
| TEST-002 | repository-facts | review | 确认当前仓库被定位为部署源码仓库，而非业务应用仓库 | 仓库角色定义 | `1.2` | done | passed | 人工核对 `repository-facts.md`、`.env.example`、`README.md` | 已明确未知应用事实通过显式配置承接 | `DOMAINS/repository-facts.md` | |
| TEST-003 | repository-facts | review | 确认未知应用运行事实已收敛为显式配置契约 | 配置契约 | `1.2` | done | passed | 人工核对 `.env.example`、`runtime.env` 流程、共享库验证逻辑 | 已以 `.env` / `runtime.env` / CLI 参数承接 | `scripts/lib/openclaw-common.sh` | |
| TEST-004 | findings-contract | review | 确保 findings/decision/missing-information 区分部署工具事实与应用待配置项 | 最终输出合同 | `1.3` | done | passed | 人工审阅文档引用链 | 已完成角色重判定与输出合同修正 | `DOMAINS/output-contract.md` | |
| TEST-005 | prompt-breakdown | review | 确认 prompt 拆解覆盖阶段、交付物和硬约束 | `openclaw_create_prompt.md` | `2.1` | done | passed | 人工对照 prompt 与拆解文档 | 已完成拆解骨架与后续落点设计 | `DOMAINS/prompt-breakdown.md` | 需继续细化资产级切片 |
| TEST-006 | prompt-breakdown | review | 确认所有部署资产均有对应实现落点 | 资产清单 | `2.2` | done | passed | 人工核对资产矩阵 | 已覆盖 install/upgrade/uninstall/compose/Dockerfile/.env/docs 七类资产 | `DOMAINS/prompt-breakdown.md` | 与 `DOMAINS/output-contract.md` 对齐 |
| TEST-007 | prompt-breakdown | review | 区分必须等待源码确认的决策点与可提前准备项 | 执行边界 | `2.3` | done | passed | 人工核对阻塞映射 | 已列出真实入口、端口、健康检查、secrets、目录、镜像策略等待确认项 | `DOMAINS/repository-facts.md` | 输出合同和可提前脚手架已分离 |
| TEST-008 | deployment-decision | review | 确认部署决策为“配置驱动的 Docker-first 部署工具” | `Deployment Decision` | `3.1` | done | passed | 人工审阅事实链 | 已明确 `.env` / `runtime.env` 用于承接未知应用事实 | `DOMAINS/output-contract.md` | |
| TEST-009 | deployment-assets | review | 确认部署代码资产完整且跨文件一致 | 代码产物集合 | `3.2` | done | passed | 人工审阅代码一致性 | 已生成 install/upgrade/uninstall/common-lib/compose/Dockerfile/.env.example/README | `install_openclaw.sh` | |
| TEST-010 | deployment-docs | review | 确认使用说明与边界说明完整 | 文档产物 | `3.3` | done | passed | 人工核对 README 与配置契约 | 已说明模式、默认值边界、验证方式和示例 | `README.md` | |
| TEST-011 | task-driven-dev | smoke | 确认任务恢复文档与验证矩阵已创建 | `docs/openclaw-deployment-prompt/` | `4.1` | done | passed | 检查文档文件是否存在 | 本次新增任务容器文件 | `docs/openclaw-deployment-prompt/` | |
| TEST-012 | task-driven-dev | review | 确认 checkpoint 记录 git 状态、验证债和下一步最小动作 | checkpoint | `4.2` | done | passed | 人工审阅 checkpoint | 已确认 checkpoint 记录 git 状态、验证债、风险与恢复动作，并回填稳定提交 `b734c0d` | `CHECKPOINTS/2026-03-15-01-scaffold-and-breakdown.md` | checkpoint 由后续文档提交补记实际 SHA |
| TEST-013 | task-driven-dev | review | 确认最终总结与 TODO 同步到状态文件 | `FINAL.md` / `TODO.md` | `4.3` | done | passed | 人工审阅文档一致性 | 已完成当前切片的 FINAL/TODO 回写 | `FINAL.md` | |
| TEST-014 | shell-syntax | smoke | 确认 Bash 资产至少通过语法解析 | `install/upgrade/uninstall/common-lib` | `3.2` | done | passed | `C:\Program Files\Git\bin\bash.exe -n ...` | 四个 Bash 文件均通过语法检查 | `scripts/lib/openclaw-common.sh` | Windows Git Bash 环境 |
| TEST-015 | linux-smoke | smoke | 验证 image mode 安装、升级、卸载在真实 Linux 主机可跑通 | 全链路 | `3.2` | todo | not_run | Linux smoke test | 待执行 | `install_openclaw.sh` | 验证债；当前仅有语法验证 |
| TEST-016 | linux-sudo-path | regression | 验证 sudo 非 docker-group 路径下的 Docker/Compose/Git 调用 | 权限路径 | `3.2` | todo | not_run | Linux regression test | 待执行 | `scripts/lib/openclaw-common.sh` | 验证债；需真实 Linux 环境 |

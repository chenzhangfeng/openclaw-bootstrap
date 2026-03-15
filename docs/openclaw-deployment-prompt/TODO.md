# OpenClaw Deployment Prompt TODO

## P0

- 领域 / 任务组：`Repository Fact Collection`
  - 单元：`1.2`
  - 事项：补齐真实 OpenClaw 应用源码事实并确认启动入口、依赖定义、配置入口、容器化现状。
  - 原因：当前仓库仅包含 prompt 和 agent 规则，缺少应用代码。
  - 依赖：真实应用仓库或等价源码快照。
  - 下一步：读取 `README*`、`pyproject.toml`、`requirements*.txt`、`Dockerfile`、`compose*`、`scripts/`、`docs/`。

## P1

- 领域 / 任务组：`Prompt Decomposition`
  - 单元：`2.2`
  - 事项：在拿到真实源码后，为每个部署资产补具体变量、命令、端口、健康检查和回滚细节。
  - 原因：当前只完成了资产级拆解，事实级实现仍依赖真实应用仓库。
  - 依赖：`DOMAINS/prompt-breakdown.md`、真实 OpenClaw 源码
  - 下一步：对照真实仓库把资产矩阵补到命令级实现。

## P2

- 领域 / 任务组：`Validation And Handoff`
  - 单元：`4.3`
  - 事项：任务完成后回填最终总结与验证结论。
  - 原因：当前任务仍在进行中。
  - 依赖：部署资产生成与验证完成。
  - 下一步：在可执行阶段结束后更新 `FINAL.md`。

# OpenClaw Deployment Prompt TODO

## P0

- 领域 / 任务组：`Validation And Handoff`
  - 单元：`TEST-015`
  - 事项：在真实 Linux 主机上跑 image mode 的安装、升级、卸载 smoke test。
  - 原因：当前仅完成语法级验证。
  - 依赖：可用的 Linux 测试机与可拉取镜像。
  - 下一步：使用一个最小镜像和显式 `OPENCLAW_RUN_CMD` / `OPENCLAW_HEALTHCHECK_URL` 执行回归。

## P1

- 领域 / 任务组：`Validation And Handoff`
  - 单元：`TEST-016`
  - 事项：验证 Docker 已安装但当前用户不在 docker group 时的 sudo 执行路径。
  - 原因：公共库已为 Docker/Compose/Git 引入 sudo 路径，需要真实环境回归。
  - 依赖：一台启用 sudo 且未加入 docker group 的 Linux 主机
  - 下一步：执行 install/upgrade/uninstall 三条路径并记录日志行为。

## P2

- 领域 / 任务组：`Deployment Asset Execution`
  - 单元：`3.2`
  - 事项：在拿到真实 OpenClaw 应用形态后，为 `.env.example` 补一组项目专用 preset。
  - 原因：当前仓库是通用部署引擎源码，应用事实仍通过显式配置注入。
  - 依赖：真实应用运行命令、端口、健康检查和 secrets 列表
  - 下一步：新增一份项目专用示例配置并补充 README。

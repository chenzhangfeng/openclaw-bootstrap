# Repository Facts Domain

## 当前仓库边界

- 当前仓库已经从“只有 prompt 的骨架仓库”推进为“OpenClaw 部署源码仓库”。
- 当前核心源码文件包括：
  - `install_openclaw.sh`
  - `upgrade_openclaw.sh`
  - `uninstall_openclaw.sh`
  - `scripts/lib/openclaw-common.sh`
  - `compose.yaml`
  - `Dockerfile`
  - `.env.example`
  - `README.md`
- 当前仓库仍然不包含业务应用源码；这是当前项目边界，不再被视为误置仓库。

## 已证实事实

### 1. 当前仓库的真实角色

- 当前仓库的职责是交付“部署工具源码”，而不是交付 OpenClaw 业务程序本体。
- 因此仓库事实分成两类：
  - 已证实的部署工具事实：脚本、Compose 模板、Dockerfile、配置契约、日志与回滚逻辑。
  - 尚未证实的应用运行时事实：真实运行命令、端口、健康检查、镜像地址、secrets、源码地址。

### 2. 对未知应用事实的处理方式

- 未知应用事实已被显式外置到：
  - `.env.example`
  - 安装后生成的 `.env`
  - 安装后生成的 `runtime.env`
  - CLI 参数，如 `--image`、`--git-repo`、`--run-cmd`、`--healthcheck-url`
- 这意味着当前仓库可以先完成部署工具开发，而不需要捏造业务应用细节。

### 3. 已实现的部署能力

- Docker-first 安装、升级、卸载三条主路径。
- Docker / Compose 自动检测与主流 Linux 发行版安装逻辑。
- 资源预检、端口检查、日志文件回退、systemd Compose wrapper、回滚与幂等保护。
- image mode 与 build mode 双模式。
- 通过 `runtime.env` 收集 secrets，并把通用应用配置保持为显式输入。

## 仍待配置的信息

| 项目 | 当前状态 | 当前处理方式 | 后续动作 |
| --- | --- | --- | --- |
| 真实运行命令 | 未证实 | 通过 `OPENCLAW_RUN_CMD` 显式输入 | 在真实应用确定后补默认值或 preset |
| 真实镜像地址 | 未证实 | 通过 `OPENCLAW_IMAGE_REF` 输入 | 在有官方镜像后补项目专用示例 |
| 源码仓库地址 | 未证实 | 通过 `OPENCLAW_GIT_REPO` 输入 | 在 build mode 对接真实仓库 |
| 健康检查入口 | 未证实 | 通过 `OPENCLAW_HEALTHCHECK_*` 输入 | 在真实应用确定后补项目专用示例 |
| Secrets 列表 | 未证实 | 通过 `OPENCLAW_REQUIRED_SECRETS` 输入 | 在真实应用确定后补项目专用示例 |

## 对当前实现的影响

- `Repository Findings` 可以基于当前仓库写出有效结论：这是一个部署引擎源码仓库。
- `Deployment Decision` 也可以成立：采用 Docker-first、配置驱动的部署工具实现。
- `Missing Information` 不再表示“无法开发”，而是表示“应用运行时信息需要通过配置补齐”。

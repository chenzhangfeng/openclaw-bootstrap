# Repository Facts Domain

## 当前仓库边界

- 当前 git 跟踪文件只有：
  - `.gitignore`
  - `AGENTS.md`
  - `openclaw_create_prompt.md`
- 当前仓库历史仅显示：
  - `ea714d9 Initial commit`
  - `50dd898 openclaw-deploy skill`
- 当前仓库存在本地 agent skills：
  - `.agnet/skills/task-driven-dev/SKILL.md`
  - `.agnet/skills/openclaw-deployment/SKILL.md`
  - 以及其他本地 skills
- 这些 `.agnet/skills/**` 文件当前未纳入 git 跟踪，但可作为本轮执行规范来源。

## 已证实事实

### 1. OpenClaw 应用事实仍不可得

- 当前仓库没有 `README*`、`pyproject.toml`、`requirements*.txt`、`Dockerfile`、`compose*`、`Makefile`、`scripts/`、`docs/` 等典型应用或部署文件。
- 因此当前无法证实：
  - 真实启动入口
  - 项目类型（CLI / Web / API / 后台服务 / 其他）
  - 依赖定义位置
  - 配置入口
  - 现有镜像发布方式
  - systemd 接管方式
  - 健康检查方式

### 2. 当前可执行范围

- 可以执行的事项：
  - 拆解 `openclaw_create_prompt.md`
  - 建立任务留痕、验证矩阵、checkpoint 恢复点
  - 记录真实仓库缺失项与后续必须补读的文件集合
- 当前不能安全执行的事项：
  - 生成声称“基于仓库真实内容”的部署脚本
  - 写死启动命令、端口、配置路径、镜像、健康检查逻辑
  - 宣称某个 Docker-first 决策已经被应用源码证实

## 缺失信息

| 缺失项 | 当前状态 | 保守处理 | TODO |
| --- | --- | --- | --- |
| 启动入口 | 缺失 | 不生成入口相关实现，不写死命令 | 读取真实应用源码与 README |
| 项目类型 | 缺失 | 不假定 Web/API/CLI | 读取 README、服务入口、路由或 CLI 定义 |
| 依赖定义 | 缺失 | 不生成 Dockerfile 安装步骤 | 读取 `pyproject.toml` / `requirements*.txt` |
| 配置入口 | 缺失 | 不生成 `.env.example` 字段列表 | 读取环境变量说明、配置文件模板 |
| 端口与健康检查 | 缺失 | 不生成 Compose 端口映射或健康检查命令 | 读取服务监听入口与健康检查实现 |
| 现有容器化资产 | 缺失 | 不判断“直接用镜像”还是“源码构建” | 读取 `Dockerfile` / `compose*` / 发布说明 |

## 对 prompt 执行的影响

- `Repository Findings` 目前只能写“当前仓库未包含应用事实”，不能写部署事实。
- `Deployment Decision` 当前无法形成有效结论，只能保留为待源码确认。
- `Missing Information` 已经成为当前阶段的主交付之一，不是附属备注。

## 下一步依赖

- 若真实 OpenClaw 应用仓库会补到当前目录：
  - 先重新执行 `rg --files`
  - 再按 prompt 逐类读取关键文件
- 若真实应用仓库在别处：
  - 需要切换到该仓库或把对应文件复制到当前工作区后再继续。

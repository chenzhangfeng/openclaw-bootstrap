# Prompt Breakdown Domain

## 拆解目标

把 `openclaw_create_prompt.md` 从“大而全的最终输出要求”拆成可以连续推进的工作流，同时明确哪些步骤依赖真实 OpenClaw 应用事实。

## 阶段拆解

### 1. Repository Findings 准备

- 目标：
  - 收集启动入口、项目类型、依赖定义、配置入口、容器化现状。
- 输入：
  - `README*`
  - `pyproject.toml`
  - `requirements*.txt`
  - `Dockerfile`
  - `compose*`
  - `scripts/`
  - `docs/`
- 输出：
  - `Repository Findings`
  - 已证实文件引用清单
- 当前状态：
  - 受阻，当前仓库没有这些文件。

### 2. Deployment Decision 形成

- 目标：
  - 确认 Docker-first 是否成立。
  - 确认是用现有镜像还是源码构建。
  - 确认健康检查依据和是否采用 systemd 接管 Compose。
- 依赖：
  - 阶段 1 的真实仓库事实。
- 当前状态：
  - 受阻，不能脱离源码做决定。

### 3. 资产实现切片

- `install_openclaw.sh`
  - 环境检测
  - 资源预检
  - Docker / Compose 安装或校验
  - 目录准备
  - `.env` 生成
  - Compose / Dockerfile 生成或引用
  - 启动与健康检查
  - systemd wrapper 安装
  - 日志与回滚
- `upgrade_openclaw.sh`
  - 备份配置
  - 镜像拉取或重建
  - 升级后健康检查
  - 失败回滚
- `uninstall_openclaw.sh`
  - 三档卸载模式
  - 二次确认
  - 残留路径提示
- `compose.yaml`
  - 服务定义
  - 端口、卷、环境变量
  - 重启策略
  - 日志轮转
- `Dockerfile`
  - 仅在缺少现成镜像时生成
  - 支持代理、镜像源和缓存注入
- `.env.example`
  - 仅能在真实配置入口明确后填充事实字段
- 配套文档
  - Usage Guide
  - Verification
  - Compatibility Notes
  - Safety Notes

## 必须等待源码确认的决策点

- 真实启动命令或容器入口
- 默认端口或暴露接口
- 健康检查方式
- 必填 secrets / API key / token
- 数据目录、缓存目录、日志目录
- 是否已有官方镜像及其 tag 策略

## 可提前准备的通用脚手架

- 任务追踪文档
- 缺失信息模板
- 资产间一致性约束清单：
  - 服务名统一
  - 目录结构统一
  - 变量名统一
  - 日志路径统一
  - 升级/卸载与安装共享同一元数据文件
- 最终输出合同顺序：
  - `Repository Findings`
  - `Deployment Decision`
  - `Missing Information`
  - `File Tree`
  - `Complete Code`
  - `Usage Guide`
  - `Verification`
  - `Compatibility Notes`
  - `Safety Notes`

## 当前推进策略

1. 先把 prompt 拆成阶段和资产级切片。
2. 把所有依赖真实源码的项显式挂起，而不是用臆测填空。
3. 在拿到真实 OpenClaw 应用仓库后，从 `Repository Findings` 阶段恢复继续。

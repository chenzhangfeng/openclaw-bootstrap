# Output Contract Domain

## 最终输出章节映射

| 章节 | 必须包含 | 主要来源 | 当前状态 | 备注 |
| --- | --- | --- | --- | --- |
| `Repository Findings` | 当前仓库角色、部署工具事实、应用待配置项、证据文件 | 当前仓库源码 | ready | 现已能基于部署源码仓库角色形成有效结论 |
| `Deployment Decision` | Docker-first 理由、配置驱动策略、systemd 接管决策 | `Repository Findings` | ready | 不再依赖业务应用源码才能成立 |
| `Missing Information` | 缺失项、保守默认值、TODO | `DOMAINS/repository-facts.md` | ready | 当前已可输出 |
| `File Tree` | 将输出的资产结构 | `DOMAINS/prompt-breakdown.md` | ready | 资产集合已拆清 |
| `Complete Code` | 安装/升级/卸载脚本、Compose、Dockerfile、`.env.example`、文档 | 当前仓库源码 | ready | 已完成源码落地 |
| `Usage Guide` | 安装、参数、交互/非交互示例、升级、卸载 | `README.md` | ready | 已覆盖主要用法 |
| `Verification` | 安装成功验证、容器验证、日志、排障 | 代码 + 测试矩阵 | partial | 语法验证已完成，真实 Linux smoke 未完成 |
| `Compatibility Notes` | 发行版适配、Docker/Compose 要求、已知限制 | 代码实现 + `README.md` | partial | 已写通用边界，待 Linux 实机回归 |
| `Safety Notes` | 系统修改、数据删除、宿主机影响、注意事项 | 代码实现 + `README.md` | partial | 已有实现与说明，待实机回归 |

## 资产一致性约束

- 服务名、目录结构、日志路径、数据路径、配置路径必须跨脚本与 Compose 一致。
- 安装、升级、卸载脚本必须共享同一组元数据变量。
- `.env.example` 中的变量只能来自仓库已证实配置入口，不能凭空新增“看起来合理”的字段。
- 健康检查与端口暴露只能来自真实服务入口。
- systemd 若存在，只能接管 Compose 栈，不能假装接管容器内 OpenClaw 进程。

## 当前可直接复用的执行顺序

1. 读取真实应用仓库事实，补齐 `Repository Findings`。
2. 基于事实确定 `Deployment Decision`。
3. 生成完整部署资产代码。
4. 回填 `Usage Guide`、`Verification`、`Compatibility Notes`、`Safety Notes`。
5. 复核输出顺序与章节边界，确保“事实 / 默认值 / TODO”分离。

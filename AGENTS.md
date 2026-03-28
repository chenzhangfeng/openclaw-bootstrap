# 项目智能体规则 (Project Agent Rules)

## 默认执行策略 (Default Execution Policy)

- 默认无须询问确认即可继续下一个实现步骤。
- 将用户最初的继续指令视为同一任务内后续子任务的一致通过。
- 仅在重要里程碑需要业务确认、重复尝试表明陷入死循环、需要外部信息或凭据、或当前计划存在阻塞性逻辑冲突时才暂停。
- 完成一个稳定节点后，若未触发暂停条件，必须继续执行 `STATE.md` 中的“下一步最小动作”；不得仅因完成 checkpoint 或向用户汇报而自然停下。
- `待验证`、`手工联调待回补`、`验证债` 本身不属于需要停下等待确认的重要阻塞点；只要已同步记录到 `TRACKERS/TEST-MATRIX.md`、`STATE.md` 与最新 checkpoint，就继续推进下一实现切片。
- 仅当验证失败已经暴露真实逻辑冲突、涉及高风险操作、进入发布/移交门槛，或用户明确要求先补验证时，待验证事项才升级为暂停条件。

## 重要里程碑 (Major Milestones)

- 在超出已批准计划范围前需再次询问。
- 在进行不可逆转或高风险操作前需再次询问。
- 在发布、部署或其他重大交接行为前需再次询问。

## 连续性 (Continuity)

- 将状态写入项目文件，以便新的 AI 可以在没有历史聊天记录的情况下恢复工作。
- 每个稳定节点都应尝试一次非交互的稳定 Git 提交 (Git commit)。
- 当工作区混有无关改动时，优先使用显式文件列表做窄提交，而不是因为工作区脏就放弃提交。
- 若当前节点最终未提交，必须在 `STATE.md` 与最新 checkpoint 中写明原因。

## 文档编码基线 (Document Encoding Baseline)

- 仓库内中文 Markdown 与 tracker 文档默认统一使用 `UTF-8`。
- 读取或回写 `docs/**/*.md`、`docs/**/CHECKPOINTS/*.md`、`docs/**/TRACKERS/*.md`、`docs/**/DOMAINS/*.md`、`.agent/skills/**/*.md` 时，显式按 `UTF-8` 处理。
- 在 PowerShell 中优先使用带编码参数的命令，例如 `Get-Content -Encoding UTF8` 与 `Set-Content -Encoding UTF8`。
- 如果中文内容出现乱码，先按 `UTF-8` 复读确认，不要在未核实前直接覆盖原文件。

## 项目私有技能 (Project Local Skills)

- 仓库级别的私有技能存放在 `.agent/skills/<skill-name>/SKILL.md` 目录下。
- 当用户点名某个仓库私有技能，或者当前任务明确匹配时，请读取该本地 `SKILL.md` 并遵循它，即使该技能未出现在当前会话的 `可用技能 (Available skills)` 列表中。
- 对于特定于仓库的工作流，在声明已使用仓库私有版本后，优先选用私有技能而非同名的系统级技能。
- 当同一家族 skill 同时存在旧版与 `-v2` 版本时，默认优先选择 `-v2`；只有在用户明确点名旧版、旧目录文档明确要求旧版，或 `STATE.md` 已写明当前仍由旧版主导时，才继续使用旧版。
- 若旧版 skill 仅为兼容保留，不得因为名称更短或更模糊就默认回退到旧版；在接手说明、checkpoint 与 `STATE.md` 中，优先写全量 skill 名称，例如 `6a-project-management-v2`、`backend-mvp-architect-v2`、`task-driven-dev-v2`，而不是省略版本号。

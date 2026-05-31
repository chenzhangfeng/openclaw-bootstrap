# 项目智能体规则 (Project Agent Rules)

## 默认执行策略 (Default Execution Policy)

- 下文提到的 `STATE.md` 默认指当前活动任务目录中的 `docs/<Task>/STATE.md`；它是唯一运行态真相，除非用户明确要求，否则不额外维护根级第二份运行态 `STATE.md`。
- 若活动任务目录中的 `STATE.md` 或 `OUTLINE.md` 点名 `EXECUTION.md`，将其视为由 `6a-project-management-v2` 按需创建的可选执行组织文档；它只负责多线并行开发下的运行时主链路、共享 I/O、ownership 与集成 gate，不替代 `STATE.md`、`OUTLINE.md` 或 checkpoint。

- 默认无须询问确认即可继续下一个实现步骤。
- 将用户最初的继续指令视为同一任务内后续子任务的一致通过。
- 仅在重要里程碑需要业务确认、重复尝试表明陷入死循环、需要外部信息或凭据、或当前计划存在阻塞性逻辑冲突时才暂停。
- 完成一个稳定节点后，若未触发暂停条件，必须继续执行 `STATE.md` 中的“下一步最小动作”；不得仅因完成 checkpoint 或向用户汇报而自然停下。
- `待验证`、`手工联调待回补`、`验证债` 本身不属于需要停下等待确认的重要阻塞点；只要已同步记录到 `TRACKERS/TEST-MATRIX.md`、`STATE.md` 与最新 checkpoint，就继续推进下一实现切片。
- 仅当验证失败已经暴露真实逻辑冲突、涉及高风险操作、进入发布/移交门槛，或用户明确要求先补验证时，待验证事项才升级为暂停条件。
- 每个稳定节点后，先启动下一刀，再允许阶段汇报：必须先对 `STATE.md` 中的下一步最小动作执行一个真实动作，例如读取目标文件、核对实库定义、创建迁移骨架、运行下一刀的首个命令；不得在“下一刀尚未启动”时输出收口式进度消息。
- 稳定节点后的阶段汇报前，必须把“下一刀已启动”状态写回 `STATE.md`；若 `下一刀已启动 = no` 或 `下一刀启动证据` 为空，则只允许继续执行，不允许输出收口式进度消息。
- 停点采用申请制，而不是默认可停：默认视为 `stop_candidate=false`；只有显式提出停点申请，并同时补齐合法原因、停点证据、停点若通过后的受影响下一步与停点新鲜度校验，才允许进入停点判断。字段空白、缺失或未回写时，一律按继续执行处理。
- 当前批准范围未完成前，阶段进展只允许作为执行中的 `commentary` 心态汇报；`final` 只保留给合法停点或批准范围完成后的正式收口。
- 任何停点判断都必须基于刚同步过的运行态真相；若 `STATE.md`、最新 checkpoint、最近验证/审计证据、稳定提交信息四者中任一项未同步，则默认继续，不允许停下。

## 稳定节点续跑闸门 (Stable-Node Continuation Gate)

- 每当完成一个稳定节点，例如：一次实现、一轮验证、一次文档回写、一次 checkpoint、一次 `git commit`、一次阶段汇报，必须立刻重新读取当前任务的 `STATE.md`，至少复核以下字段：
  - `next_slice_id`
  - `target_files`
  - `first_command`
  - `expected_artifact`
  - `下一刀已启动`
  - `下一刀启动证据`
  - `当前批准范围完成情况`
  - `下一步是否可立即执行`
  - `是否仍在当前批准范围内`
  - `默认继续执行`
  - `stop_candidate`
  - `合法停点原因`
  - `停点申请证据`
  - `停点若通过后的受影响下一步`
  - `停点新鲜度校验`
- 若当前任务的 `STATE.md` 还没有以上字段，当前操作者必须先补齐，再决定是否停止；禁止在字段缺失时凭感觉判断“先停一下”。
- 默认真值应为：
  - `当前批准范围完成情况 = partial`
  - `下一步是否可立即执行 = yes`
  - `是否仍在当前批准范围内 = yes`
  - `默认继续执行 = yes`
  - `stop_candidate = false`
  - `合法停点原因 = none`
- `STATE.md` 中的下一步最小动作必须写成可执行四元组：`next_slice_id`、`target_files`、`first_command`、`expected_artifact`；若只剩一句模糊自然语言，视为“下一步不明确”，不得停下。
- 阶段汇报前置条件为：
  - `report_ready = (下一刀已启动 = yes) AND (下一刀启动证据 已填写)`
- 若 `report_ready = false`，则即使已经写完 checkpoint、补完文档、通过验证、切出 commit，也不得输出收口式进度消息。
- 结束当前回合前，必须显式按下式判断：
  - `should_continue = (next_slice_id 已明确) AND (first_command 可执行) AND (当前批准范围完成情况 = partial) AND (下一步是否可立即执行 = yes) AND (是否仍在当前批准范围内 = yes) AND (默认继续执行 = yes) AND (stop_candidate = false) AND (合法停点原因 = none) AND (停点新鲜度校验全为 yes)`
- 若 `should_continue = true`，则不得停止、不得把当前节点写成 `scope_complete`、不得仅输出阶段性汇报；必须直接继续执行下一步最小动作。
- 若 `should_continue = false`，必须先把 `STATE.md` 改写成新的运行态真相，再允许停止；停止原因只能来自白名单枚举，不能写“已完成稳定节点”“已提交 commit”“已写 checkpoint”“先汇报一下”等非枚举原因。
- 若准备停下，必须先满足“停点申请完整”：
  - `stop_candidate = true`
  - `合法停点原因 != none`
  - `停点申请证据` 已填写
  - `停点若通过后的受影响下一步` 已填写
  - `停点新鲜度校验` 中 `state/checkpoint/evidence/commit` 全为 `yes`
- 只要“停点申请完整”中的任一条件不满足，即使主观上想汇报或换阶段，也必须继续。
- `checkpoint`、`compile/build`、`git commit`、skill 切换、阶段汇报都会触发一次续跑闸门复核；它们只能作为恢复点，不能单独构成停点。

## 重要里程碑 (Major Milestones)

- 在超出已批准计划范围前需再次询问。
- 在进行不可逆转或高风险操作前需再次询问。
- 在发布、部署或其他重大交接行为前需再次询问。

## 连续性 (Continuity)

- 将状态写入项目文件，以便新的 AI 可以在没有历史聊天记录的情况下恢复工作。
- 每个稳定节点都应尝试一次非交互的稳定 Git 提交 (Git commit)。
- 当工作区混有无关改动时，优先使用显式文件列表做窄提交，而不是因为工作区脏就放弃提交。
- 若当前节点最终未提交，必须在 `STATE.md` 与最新 checkpoint 中写明原因。
- 活跃任务的 `STATE.md` 必须长期保留一组可机器判读的续跑字段：`next_slice_id`、`target_files`、`first_command`、`expected_artifact`、`下一刀已启动`、`下一刀启动证据`、`当前批准范围完成情况`、`下一步是否可立即执行`、`是否仍在当前批准范围内`、`默认继续执行`、`stop_candidate`、`合法停点原因`、`停点申请证据`、`停点若通过后的受影响下一步`、`停点新鲜度校验`。

## 文档编码基线 (Document Encoding Baseline)

- 仓库内中文 Markdown 与 tracker 文档默认统一使用 `UTF-8`。
- 读取或回写 `docs/**/*.md`、`docs/**/CHECKPOINTS/*.md`、`docs/**/TRACKERS/*.md`、`docs/**/DOMAINS/*.md`、`.agent/skills/**/*.md` 时，显式按 `UTF-8` 处理。
- 在 PowerShell 中优先使用带编码参数的命令，例如 `Get-Content -Encoding UTF8` 与 `Set-Content -Encoding UTF8`。
- 如果中文内容出现乱码，先按 `UTF-8` 复读确认，不要在未核实前直接覆盖原文件。

## 项目私有技能 (Project Local Skills)

- 仓库级别的私有技能存放在 `.agent/skills/<skill-name>/SKILL.md` 目录下。
- 当用户点名某个仓库私有技能，或者当前任务明确匹配时，请读取该本地 `SKILL.md` 并遵循它，即使该技能未出现在当前会话的 `可用技能 (Available skills)` 列表中。
- 对于特定于仓库的工作流，在声明已使用仓库私有版本后，优先选用私有技能而非同名的系统级技能。
- 当任务进入多线并行开发、共享 I/O、串行集成的阶段时，优先由 `6a-project-management-v2` 判断是否创建 `EXECUTION.md`；`task-driven-dev-v2` 只在其被点名为活跃文档时读取并遵守。
- 当同一家族 skill 同时存在旧版与 `-v2` 版本时，默认优先选择 `-v2`；只有在用户明确点名旧版、旧目录文档明确要求旧版，或活动任务目录的 `STATE.md` / 交接文档已写明当前仍由旧版主导时，才继续使用旧版。
- 若旧版 skill 仅为兼容保留，不得因为名称更短或更模糊就默认回退到旧版；在接手说明、checkpoint 与 `STATE.md` 中，优先写全量 skill 名称，例如 `6a-project-management-v2`、`backend-mvp-architect-v2`、`task-driven-dev-v2`，而不是省略版本号。
- `.agent/` 即使在当前宿主仓库中被 `.gitignore` 忽略，也不影响其权威性；这通常只表示 `.agent/` 作为外部引入的独立 Git 库单独管理，而不是受宿主仓库版本控制。
- 对于由 skill 覆盖的工作流、停点规则、续跑协议、文档协议与协作约束，相关 skill 必须被视为唯一真相源。
- `AGENTS.md`、`README.md` 与仓库级辅助文档只承担入口说明、恢复辅助与跨工具可见性职责；它们不得反向推翻或覆盖 skill 中的同类规则。
- 若 `AGENTS.md`、`README.md`、`docs/` 与相关 skill 出现冲突，在该 skill 所覆盖的职责范围内，一律以 skill 为准；需要修正时，应先修 skill，再同步镜像文件，而不是反过来。

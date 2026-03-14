请你基于以下核心要求，为 OpenClaw 编写一个企业级、高通用、高容错的一键安装部署 Shell 脚本（bash）：

核心目标
实现 OpenClaw 的全自动安装、依赖配置、服务注册、启动测试全流程。
脚本需具备极强通用性，兼容主流 Linux 发行版（Ubuntu/Debian/CentOS/RHEL/Arch）。
容错性拉满，能处理各类异常场景，保障“非成功即全额回滚”。
可复用性强，支持模块化调用与 CLI 自定义参数。
具体功能要求
1. 环境检测与资源校验模块
系统与权限：检测操作系统发行版与 CPU 架构。检测当前执行用户，若非 root 或不具备 sudo 权限，必须中断并提示“OpenClaw 需要高系统权限以执行核心调度任务，请切换至 root 或使用 sudo 执行”。
硬件与端口：检测可用内存（需 > 2GB）、磁盘剩余空间（需 > 5GB）；检测 OpenClaw 需使用的默认端口是否被占用，若占用则阻断并提示。
依赖校验：检测核心依赖（Python 3.8+、Git、gcc/g++、Docker），缺失则自动安装。同时针对网络连通性，自动为包管理器和 pip 切换至国内高质量镜像源。
2. 环境隔离与保护
严格的虚拟环境：尽管以高权限运行，但为了遵循 PEP 668 防止污染宿主机核心系统，强制要求在安装目录（如 /opt/openclaw/venv）下创建独立的 Python 虚拟环境，后续所有依赖安装及服务启动均调用该 venv 的解释器执行。
3. 容错拦截与回滚模块
全局异常捕获：头部开启 set -euo pipefail。使用 Bash 的 trap 监听 ERR、EXIT 和 INT 信号。
重试与回滚：网络请求和依赖安装失败时，启用退避重试机制（最多 3 次）。任意不可逆步骤执行失败，触发 trap 自动执行 rollback 函数（清理残留文件和临时进程、撤销系统修改）。
重复安装检测：检测到目标目录已存在时，提供「备份后覆盖安装 / 中止退出 / 保留源码仅更新环境」三种交互式选项。
4. 服务注册与进程接管
Systemd 接管：脚本完成代码拉取和环境配置后，需在 /etc/systemd/system/ 动态生成 openclaw.service 守护进程文件。
服务配置中需设定 User=root 或当前拥有 sudo 权限的用户，包含自动重启、按日志轮转输出等配置。
配置自启，并通过 systemctl 启动服务。
5. 可复用性与接口设计
核心逻辑完全封装并解耦（如 check_env()、setup_virtualenv()、deploy()、register_service()）。
顶部集中暴露全局变量（包括 INSTALL_DIR=/opt/openclaw, VERSION=latest, LOG_FILE=/var/log/openclaw_install.log）。
支持命令行参数控制（如 ./install.sh --dir /usr/local/openclaw --port 8080 --unattended(无交互静默模式)）。
6. 交互与交付物
日志结构化：终端打印带颜色高亮的格式化日志（[INFO]/[WARN]/[ERROR]），全量调试日志追加录入至 $LOG_FILE。
安装完成后，输出高亮 summary：测试状态结果、服务管理快捷命令（start/stop/logs）、Web 或 API 访问地址。
输出要求
提供单个可执行的完整的 .sh 代码，不允许省略逻辑，关键链路逐行附加上中文注释。
配套一份 Markdown 格式的使用说明（含支持的参数、默认文件结构、日常维护所需命令）。
由于需要高权限运行，请在文档中特别标注对宿主的潜在影响及安全建议。
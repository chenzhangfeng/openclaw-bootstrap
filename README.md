# OpenClaw 部署工具箱

本仓库为 OpenClaw AI 智能体系统提供 **跨平台一键部署** 解决方案，覆盖 Windows / macOS / Linux 三大平台，支持 **预装版（fat）** 和 **联网版（slim）** 两种分发模式。

---

## 项目结构

```text
openclaw-bootstrap/
│
├── build/                           # 构建脚本（开发者/打包者使用）
│   ├── build-windows.ps1            #   Windows 构建（PowerShell）
│   ├── build-unix.sh                #   macOS / Linux 构建（Bash）
│   └── prune-platform.js            #   核心：跨平台 node_modules 瘦身工具
│
├── launchers/                       # 各平台启动器模板
│   ├── windows/                     #   Windows 启动器（.bat 批处理）
│   │   ├── start.bat                #     一键启动
│   │   ├── update.bat               #     一键更新
│   │   └── 0.配置AI密钥.bat          #     API 密钥配置向导
│   └── unix/                        #   macOS / Linux 启动器（.sh 脚本）
│       ├── start.sh                 #     一键启动
│       ├── update.sh                #     一键更新
│       └── setup-key.sh             #     API 密钥配置向导
│
├── portable/                        # 跨平台共享文件
│   ├── scripts/set-key.js           #   API 密钥注入脚本
│   ├── data/openclaw.json           #   预置默认配置
│   └── README.md                    #   用户使用说明
│
├── openclaw/                        # OpenClaw 官方源码（克隆或 submodule）
│
├── dist/                            # 构建产物输出目录（已 .gitignore）
│
├── install_openclaw.sh              # Linux 服务器版：Docker 模式安装脚本
├── upgrade_openclaw.sh              # Linux 服务器版：热更新脚本
├── uninstall_openclaw.sh            # Linux 服务器版：卸载脚本
├── compose.yaml                     # Docker Compose 编排模板
└── Dockerfile                       # Docker 构建镜像
```

---

## 两种分发模式

| 模式 | 含义 | 包含 node_modules | 首次启动需联网 | 压缩后体积 | 适用场景 |
|:----:|------|:--:|:--:|-----------|---------|
| **fat** | 预装版 | ✅ 是（已平台瘦身） | ❌ 不需要 | ~150-200MB | 小白用户、离线环境 |
| **slim** | 联网版 | ❌ 否 | ✅ 需要 | ~30-50MB | 技术用户、网速好的场景 |

**fat 模式**会在构建时自动运行 `prune-platform.js`，删除所有非目标平台的原生二进制包（如 Windows 构建会删除全部 `linux-*`、`darwin-*` 的包），大幅压缩体积。

---

## 快速构建

### Windows 版

```powershell
# 预装版（解压即用，推荐）
powershell -ExecutionPolicy Bypass -File .\build\build-windows.ps1 -Mode fat

# 联网版（包体小，首次启动需联网安装依赖）
powershell -ExecutionPolicy Bypass -File .\build\build-windows.ps1 -Mode slim
```

### macOS 版

```bash
# Apple Silicon (M1/M2/M3) 预装版
bash build/build-unix.sh darwin arm64 fat

# Intel Mac 联网版
bash build/build-unix.sh darwin x64 slim
```

### Linux 版

```bash
# x64 预装版
bash build/build-unix.sh linux x64 fat

# ARM64 联网版（树莓派等）
bash build/build-unix.sh linux arm64 slim
```

### 构建产物

所有产物输出到 `dist/` 目录，命名规则为 `openclaw-{平台}-{架构}-{模式}`：

```text
dist/
├── openclaw-win-x64-fat/
├── openclaw-win-x64-slim/
├── openclaw-darwin-arm64-fat/
├── openclaw-linux-x64-fat/
└── ...
```

将对应目录压缩为 `.zip`（Windows）或 `.tar.gz`（macOS/Linux）即可分发。

---

## 用户使用流程

### Windows 用户

1. 解压收到的压缩包到**纯英文路径**（如 `D:\openclaw-portable`）
2. 双击 `0.配置AI密钥.bat`，按菜单选择厂商并粘贴密钥
3. 双击 `start.bat`，等待浏览器自动打开

### macOS / Linux 用户

```bash
# 赋予执行权限
chmod +x *.sh

# 配置 API 密钥
./setup-key.sh

# 启动
./start.sh
```

---

## Linux 服务器版（Docker 部署）

适用于有 Linux 运维经验的用户或硬件盒子场景：

```bash
# 镜像模式安装
./install_openclaw.sh \
  --mode image \
  --image registry.example.com/openclaw:latest \
  --port 8080

# 源码构建模式
./install_openclaw.sh \
  --mode build \
  --git-repo https://github.com/openclaw/openclaw.git \
  --git-ref main \
  --port 8080

# 热更新
./upgrade_openclaw.sh --dir /opt/openclaw --git-ref main

# 卸载（仅停容器）
./uninstall_openclaw.sh --dir /opt/openclaw --mode containers
```

---

## 防坑指南

> [!CAUTION]
> **杀毒软件误报**：由于脚本调用了便携版 Node.js 并自动运行 npm 安装，极易被安全软件拦截。请在使用前暂时关闭杀毒软件或将整个目录加入白名单。

> [!WARNING]
> **路径限制（Windows）**：安装路径中不能包含中文、空格或特殊字符。推荐解压到 `D:\openclaw-portable` 这类纯英文根目录。

> [!TIP]
> **VC++ 运行库**：部分 Windows 电脑可能缺少 C++ 运行库导致闪退，请安装微软常用运行库合集后重试。

---

## 技术细节

- **Node.js 版本**：v22.22.1 LTS（OpenClaw 要求 ≥22.16.0）
- **包管理器**：pnpm v10+
- **环境隔离**：所有环境变量（`PATH`、`npm_config_prefix`、`PNPM_HOME`、`PNPM_STORE_DIR`、`PLAYWRIGHT_BROWSERS_PATH`、`OPENCLAW_STATE_DIR`）均劫持到便携包内部，绝不污染宿主系统
- **安全沙盒**：默认配置为 `workspace` 受限模式，AI 仅可访问 `data/workspace/` 目录

# OpenClaw 绿盒化便携打包指南 (Windows Portable Build Guide)

本目录包含了用于直接触达“纯小白用户”的 Windows 本地运行引流包的基础批处理脚本。由于普通家庭版 Windows 运行 Docker 具有较高配置门槛与故障率，此包专门设计为“解压即可双击执行”的极端易用流。

## 推荐用户流程

1. 解压后先双击 `start.bat`
2. 进入 OpenClaw 页面后，优先在页面内完成模型 / API 配置
3. 只有当当前页面暂未提供配置入口时，再使用 `0.配置AI密钥.bat` 作为兼容兜底工具

## 目录结构要求
当您制作面向用户最终分发的 `.zip` 文件时，请确保解压后的文件夹遵循以下目录结构：

```text
openclaw-portable/
│
├── start.bat               # 启动脚本
├── update.bat              # 更新脚本
├── README.md               #也就是本文档
│
├── node/                   # (核心) Windows 便携版 Node.js
│   ├── node.exe
│   ├── npm.cmd
│   └── node_modules/       # npm 全局库 (如 pnpm)
│
├── git/                    # (可选) 若需要热拉取代码，则嵌入精简版 Git for Windows Portable
│   ├── bin/git.exe
│   └── ...
│
├── browsers/               # (必选) 提前下载好的 Playwright 浏览器内核 (ms-playwright)
├── 修复环境_安装C++运行库.exe # (必备) 微软常用运行库合集，用于小白电脑缺少dll时一键修复
│
└── openclaw/               # (核心) OpenClaw真实的源码目录 (包含 package.json 等)
    ├── package.json
    └── ...
```

## 便携基础架构如何制作？
为了不污染用户的操作系统环境变量（例如用户自己装的老旧 Node 或是版本冲突），我们采用相对路径劫持 `PATH` 环境变量的技术。

### 第一步：获取便携 Node.js
1. 前往 Node.js 官方下载页面，下载 Windows zip 包（如 `node-v22.x.x-win-x64.zip`，OpenClaw 推荐 Node 22+）。
2. 将其中的内容解压存入便携包的 `node/` 目录下（确保 `node/node.exe` 存在）。

### 第二步：应用代码挂载与发版预装
我们将完整的 OpenClaw 源码放在和 `.bat` 同级的 `openclaw/` 目录下。
> **发版强烈建议**：为了追求极致的小白体验（真正的“极速双击运行”），建议您在打包前，先在自己的电脑上运行 `start.bat`，让系统自动下载好 `node_modules` 依赖并完成各种预构建。然后再把完整的 `openclaw/` 连带体积庞大的 `node_modules` 一起压缩分发！这样用户本地就甚至无需耗费大量时间走 npm 下载了。

## 安全与小白防坑指南 (Defensive Engineering)
> [!CAUTION]
> 1. **杀毒软件误报拦截**：由于脚本调用了便携版 Node 并自动运行 npm 安装，极易被 360 等杀软后台静默拦截。**必须**在下载页面和视频教程里使用醒目的红字强调：“本工具为开源项目，如遇杀毒软件拦截，请点击‘允许’或暂时关闭防病毒软件后再运行。”
> 2. **中文与空格路径灾难**：`start.bat` 已内置严格的路径合法性检测。如果小白将自解压包放在桌面（往往带中文或空格），脚本会直接拦截运行并弹窗警告，强制要求用户将其移动至 `D:\OpenClaw` 此类安全根目录。
> 3. **缺失 VC++ 运行库**：许多极其干净的家庭版电脑在运行 Node.js 底层 C++ 扩展包（如 sqlite3 / canvas）时会报 dll 缺失。请务必在压缩包根目录放置一份 `修复环境_安装C++运行库.exe`（微软常用运行库合集 v2024 等常见版本），并在安装说明中重点引导用户：“报错闪退就点它！”
> 4. **Playwright 浏览器依赖**：绝不要指望小白会自己执行 `playwright install` 并等待缓慢的境外网速下载几百兆内核！请您在打包前，先在自己电脑上装好，然后把 `%LOCALAPPDATA%\ms-playwright` 里的整个文件夹原封不动地拷贝到本便携包的 `browsers/` 文件夹下。`start.bat` 会通过环境变量自动将其挂载为本地脱机脱网浏览器内核。

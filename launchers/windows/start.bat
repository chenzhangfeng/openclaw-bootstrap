@echo off
chcp 65001 >nul
title OpenClaw 一键启动工具

:: ==========================================
:: OpenClaw 绿盒化便携启动脚本
:: 专门针对不具备开发环境的 Windows 个人用户
:: ==========================================

echo ===================================================
echo.
echo           欢迎使用 OpenClaw AI 智能体系统
echo.
echo   - 正在检查本地环境，请耐心等待...
echo   - 如遇安全软件拦截，请允许放行
echo.
echo ===================================================
echo.
echo   首次进入后，优先在页面里完成模型 / API 配置。
echo   只有当页面暂未提供入口时，再使用兼容配置工具。

:: 1. 环境路径隔离
set "BASE_DIR=%~dp0"
set "BASE_DIR=%BASE_DIR:~0,-1%"

:: 检测路径中是否包含空格
set "CHECK_SPACE=%BASE_DIR: =%"
if not "%CHECK_SPACE%"=="%BASE_DIR%" (
    if not defined DEV_MODE (
        echo.
        echo [致命错误] 当前文件夹路径中包含空格！
        echo 请不要将本程序放在桌面或带有空格的文件夹下。
        echo 请移动到磁盘纯英文根目录（例如 D:\OpenClaw）后重试。
        echo.
        pause
        exit /b 1
    )
    echo [警告] 路径含空格，DEV_MODE 已启用，继续运行...
)

:: 检测路径中是否包含非ASCII字符（中文等）
:: 用 for /f 配合白名单字符集做减法，若剩余内容非空则含非法字符
set "_PATHCHECK=%BASE_DIR%"
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789:\-_." %%a in ("%_PATHCHECK%") do (
    if not "%%a"=="" (
        if not defined DEV_MODE (
            echo.
            echo [致命错误] 当前文件夹路径中包含中文或特殊字符！
            echo 请将整个 OpenClaw 文件夹移动到磁盘纯英文根目录（例如 D:\OpenClaw）
            echo.
            pause
            exit /b 1
        )
        echo [警告] 路径含非ASCII字符，DEV_MODE 已启用，继续运行...
    )
)

:: 设定便携版 Node.js 路径
set "NODE_DIR=%BASE_DIR%\node"
set "GIT_DIR=%BASE_DIR%\git\bin"

IF NOT EXIST "%NODE_DIR%\node.exe" (
    echo [错误] 找不到便携版 Node.js 环境！
    echo 请确认您下载的是完整的压缩包，且未改动目录结构。
    echo 缺失路径: %NODE_DIR%\node.exe
    pause
    exit /b 1
)

:: 将便携版工具强制放置于 PATH 最优先位置
set "PATH=%NODE_DIR%;%GIT_DIR%;%PATH%"

:: 劫持 npm 全局安装路径到便携包内部，绝不污染宿主系统
set "npm_config_prefix=%NODE_DIR%"

:: 劫持 pnpm 缓存和全局安装路径到便携包内部，避免在磁盘根目录生成 .pnpm-store
set "PNPM_HOME=%BASE_DIR%\pnpm-global"
set "PNPM_STORE_DIR=%BASE_DIR%\pnpm-store"

:: 设定脱机版 Playwright 浏览器缓存路径
set "PLAYWRIGHT_BROWSERS_PATH=%BASE_DIR%\browsers"

:: 配置劫持：让 OpenClaw 将配置文件存放在当前文件夹下，实现便携开箱即用
set "OPENCLAW_STATE_DIR=%BASE_DIR%\data"
set "CLAWDBOT_STATE_DIR=%BASE_DIR%\data"

:: 2. 检查并安装依赖
echo.
echo [1/2] 正在检查运行依赖...
if exist "%BASE_DIR%\openclaw\package.json" (
    cd /d "%BASE_DIR%\openclaw"

    :: 检测 pnpm 是否已安装，避免每次重复安装
    where pnpm >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo 正在安装包管理器 pnpm...
        call npm install -g pnpm --registry=https://registry.npmmirror.com
    )

    :: 检测 node_modules 是否已存在，存在则跳过全量安装
    if not exist "%BASE_DIR%\openclaw\node_modules\.pnpm" (
        echo 正在安装项目依赖（首次运行需要几分钟）...
        call pnpm install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir "%PNPM_STORE_DIR%"
        if %ERRORLEVEL% neq 0 (
            echo.
            echo [警告] 依赖包安装可能未完全成功，后续可能会出现异常。
            echo 请检查您的网络连接并重试。
            pause
        )
    ) else (
        echo [OK] 依赖已就绪，跳过安装。
    )
) else (
    echo [提示] 未发现 openclaw 源码目录，跳过依赖安装。
)

:: 3. 启动 OpenClaw
echo.
echo [2/2] 正在核心引擎拉起中...
echo ---------------------------------------------------
echo 如果您是首次运行，服务可能需要几分钟初始化构建界面。
echo 启动成功后，会自动在浏览器中打开使用页面。
echo 如果页面里尚未配置模型，请优先在页面内完成设置。
echo ---------------------------------------------------

if exist "%BASE_DIR%\openclaw\package.json" (
    cd /d "%BASE_DIR%\openclaw"
    call pnpm start
) else (
    echo [致命错误] 找不到 openclaw 源码，请确保存放在 openclaw 目录下！
    pause
    exit /b 1
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [错误] OpenClaw 异常退出，请查看上方的报错信息截图发给客服群。
    pause
    exit /b 1
)

echo.
echo [完成] OpenClaw 服务已正常停止。
pause

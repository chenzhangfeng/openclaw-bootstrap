@echo off
chcp 65001 >nul
title OpenClaw 一键更新工具

echo ===================================================
echo.
echo           欢迎使用 OpenClaw 自动更新工具
echo.
echo   - 正在连接服务器获取最新功能包...
echo   - 更新过程中请勿关闭本窗口
echo.
echo ===================================================

set "BASE_DIR=%~dp0"
set "BASE_DIR=%BASE_DIR:~0,-1%"

set "NODE_DIR=%BASE_DIR%\node"
set "GIT_DIR=%BASE_DIR%\git\bin"

:: 设置局部 PATH，优先使用便携包内的 Git 和 Node
set "PATH=%NODE_DIR%;%GIT_DIR%;%PATH%"
:: 劫持 npm / pnpm 全局安装和缓存路径到便携包内部
set "npm_config_prefix=%NODE_DIR%"
set "PNPM_HOME=%BASE_DIR%\pnpm-global"
set "PNPM_STORE_DIR=%BASE_DIR%\pnpm-store"

:: 1. 检查 Git 是否可用
git --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [错误] 找不到便携版 Git，无法执行在线更新！
    echo 请确保下载的是完整增量包。
    pause
    exit /b 1
)

:: 2. 检查是否为合法的 Git 仓库
if not exist "%BASE_DIR%\.git" (
    echo [错误] 当前目录不是受版本控制的仓库，无法自动更新代码。
    pause
    exit /b 1
)

:: 3. 备份用户本地修改后拉取最新代码
echo [正在备份] 暂存您的本地修改...
git stash --include-untracked >nul 2>&1

echo [正在拉取] 正在从代码库同步最新更新...
git fetch --all
if %ERRORLEVEL% neq 0 (
    echo [警告] 无法连接到代码仓库，可能网络异常。
    git stash pop >nul 2>&1
    pause
    exit /b 1
)

git reset --hard origin/main
if %ERRORLEVEL% neq 0 (
    echo [错误] 代码文件同步失败。
    git stash pop >nul 2>&1
    pause
    exit /b 1
)
echo [OK] 核心文件更新成功！

:: 4. 恢复用户的本地修改
git stash pop >nul 2>&1

:: 5. 更新依赖库
echo.
echo [正在同步] 正在更新 Node.js 运行依赖库...
if exist "%BASE_DIR%\openclaw\package.json" (
    cd /d "%BASE_DIR%\openclaw"
    where pnpm >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        call npm install -g pnpm --registry=https://registry.npmmirror.com
    )
    call pnpm install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir "%PNPM_STORE_DIR%"
)

echo.
echo ===================================================
echo [完成] OpenClaw 已经更新到最新版本！
echo 您现在可以关闭此窗口，并双击 "start.bat" 运行系统。
echo ===================================================
pause

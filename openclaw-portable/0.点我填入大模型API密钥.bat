@echo off
chcp 65001 >nul
title OpenClaw API 密钥初始化工具

echo ===================================================
echo.
echo      OpenClaw 引流版 - 极速配置向导
echo.
echo   只需填写一次大模型 API 密钥，即可永久解锁所有功能！
echo.
echo ===================================================

set "BASE_DIR=%~dp0"
set "BASE_DIR=%BASE_DIR:~0,-1%"
set "NODE_DIR=%BASE_DIR%\node"

IF NOT EXIST "%NODE_DIR%\node.exe" (
    echo [错误] 未发现 Node.js 环境，本工具需要便携版 Node.js。
    pause
    exit /b 1
)

echo.
echo 请选择您使用的大模型厂商:
echo.
echo   [1] DeepSeek （推荐，国内最强性价比）
echo   [2] OpenAI / ChatGPT
echo   [3] 通义千问 (阿里云)
echo   [4] 零一万物 (Yi)
echo   [5] Moonshot (月之暗面/Kimi)
echo   [6] 本地 Ollama (无需密钥)
echo   [7] 其他兼容 OpenAI 的厂商
echo.

set /p VENDOR_CHOICE="请输入编号 (1-7): "

if "%VENDOR_CHOICE%"=="1" (
    set "PROVIDER_NAME=deepseek"
    set "BASE_URL=https://api.deepseek.com/v1"
) else if "%VENDOR_CHOICE%"=="2" (
    set "PROVIDER_NAME=openai"
    set "BASE_URL=https://api.openai.com/v1"
) else if "%VENDOR_CHOICE%"=="3" (
    set "PROVIDER_NAME=qwen"
    set "BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
) else if "%VENDOR_CHOICE%"=="4" (
    set "PROVIDER_NAME=yi"
    set "BASE_URL=https://api.lingyiwanwu.com/v1"
) else if "%VENDOR_CHOICE%"=="5" (
    set "PROVIDER_NAME=moonshot"
    set "BASE_URL=https://api.moonshot.cn/v1"
) else if "%VENDOR_CHOICE%"=="6" (
    set "PROVIDER_NAME=ollama"
    set "BASE_URL=http://127.0.0.1:11434/v1"
    echo.
    echo [提示] Ollama 模式无需密钥，将使用占位符自动配置。
    echo placeholder | "%NODE_DIR%\node.exe" "%BASE_DIR%\scripts\set-key.js" "%PROVIDER_NAME%" "%BASE_URL%"
    goto :done
) else if "%VENDOR_CHOICE%"=="7" (
    set "PROVIDER_NAME=custom"
    set /p BASE_URL="请输入厂商的 API 地址 (例如 https://api.xxx.com/v1): "
) else (
    echo [错误] 无效的选择！
    pause
    exit /b 1
)

echo.
set /p API_KEY="请粘贴您的 API 密钥 (例如 sk-xxxxxxxxx) 后按回车: "

if "%API_KEY%"=="" (
    echo [错误] 密钥不能为空！
    pause
    exit /b 1
)

echo.
echo [正在配置] 正在将密钥安全写入引擎系统...
echo %API_KEY% | "%NODE_DIR%\node.exe" "%BASE_DIR%\scripts\set-key.js" "%PROVIDER_NAME%" "%BASE_URL%"

if %ERRORLEVEL% neq 0 (
    echo [失败] 密钥写入过程出现异常。
    pause
    exit /b 1
)

:done
echo.
echo ===================================================
echo   配置已全部完成！现在您随时可以双击【start.bat】
echo   开启属于您的私人 AI Agent 之旅！
echo ===================================================
pause

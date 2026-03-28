#!/usr/bin/env bash
set -euo pipefail

echo "==================================================="
echo ""
echo "      Welcome to OpenClaw AI Agent System"
echo ""
echo "  - Checking local environment..."
echo "  - If blocked by security software, please allow"
echo ""
echo "==================================================="
echo ""
echo "  First launch: start OpenClaw first, then configure model/API in the web UI."
echo "  Only use the compatibility setup script if the current page has no config entry yet."

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
NODE_DIR="$BASE_DIR/node"

# 检查路径中是否包含空格
if [[ "$BASE_DIR" == *" "* ]]; then
    echo ""
    echo "[FATAL] Path contains spaces!"
    echo "Please move OpenClaw to a path without spaces (e.g. /opt/openclaw)"
    exit 1
fi

# 检查 Node.js
if [ ! -f "$NODE_DIR/bin/node" ]; then
    echo "[ERROR] Portable Node.js not found!"
    echo "Expected: $NODE_DIR/bin/node"
    exit 1
fi

# 设置环境变量
export PATH="$NODE_DIR/bin:$PATH"
export npm_config_prefix="$NODE_DIR"
export PNPM_HOME="$BASE_DIR/pnpm-global"
export PNPM_STORE_DIR="$BASE_DIR/pnpm-store"
export PLAYWRIGHT_BROWSERS_PATH="$BASE_DIR/browsers"
export OPENCLAW_STATE_DIR="$BASE_DIR/data"
export CLAWDBOT_STATE_DIR="$BASE_DIR/data"

# 安装依赖
echo ""
echo "[1/2] Checking dependencies..."
if [ -f "$BASE_DIR/openclaw/package.json" ]; then
    cd "$BASE_DIR/openclaw"

    if ! command -v pnpm &>/dev/null; then
        echo "Installing pnpm..."
        npm install -g pnpm --registry=https://registry.npmmirror.com
    fi

    if [ ! -d "$BASE_DIR/openclaw/node_modules/.pnpm" ]; then
        echo "Installing project dependencies (first run may take a few minutes)..."
        pnpm install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir "$PNPM_STORE_DIR"
    else
        echo "[OK] Dependencies ready."
    fi
fi

# 启动 OpenClaw
echo ""
echo "[2/2] Starting OpenClaw engine..."
echo "---------------------------------------------------"
echo "First run may take a few minutes to initialize."
echo "A browser window will open automatically when ready."
echo "If no model is configured yet, please finish it in the product page first."
echo "---------------------------------------------------"

if [ -f "$BASE_DIR/openclaw/package.json" ]; then
    cd "$BASE_DIR/openclaw"
    pnpm start
else
    echo "[FATAL] OpenClaw source not found in openclaw/ directory!"
    exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

echo "==================================================="
echo ""
echo "      OpenClaw Auto Update Tool"
echo ""
echo "  - Connecting to server for latest updates..."
echo "  - Do not close this window during update"
echo ""
echo "==================================================="
echo ""
echo "  For novice-friendly release packages, re-downloading the latest archive is preferred."
echo "  This script is mainly a compatibility path for Git-based distributions."

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
NODE_DIR="$BASE_DIR/node"
GIT_DIR="$BASE_DIR/git/bin"

export PATH="$NODE_DIR/bin:$GIT_DIR:$PATH"
export npm_config_prefix="$NODE_DIR"
export PNPM_HOME="$BASE_DIR/pnpm-global"
export PNPM_STORE_DIR="$BASE_DIR/pnpm-store"

# 检查 Git
if ! command -v git &>/dev/null; then
    echo "[ERROR] Git not found! Cannot perform online update."
    exit 1
fi

# 检查 Git 仓库
if [ ! -d "$BASE_DIR/.git" ]; then
    echo "[Info] This directory is not a Git repository, so the compatibility updater cannot run."
    echo "[Suggestion] Please download the latest release archive and replace the old folder."
    exit 1
fi

# 暂存用户修改
echo "[Stashing] Saving your local changes..."
git stash --include-untracked 2>/dev/null || true

# 拉取最新代码
echo "[Pulling] Fetching latest updates..."
git fetch --all
if [ $? -ne 0 ]; then
    echo "[WARN] Cannot connect to repository."
    git stash pop 2>/dev/null || true
    exit 1
fi

git reset --hard origin/main
echo "[OK] Source files updated!"

# 恢复用户修改
git stash pop 2>/dev/null || true

# 更新依赖
echo ""
echo "[Syncing] Updating dependencies..."
if [ -f "$BASE_DIR/openclaw/package.json" ]; then
    cd "$BASE_DIR/openclaw"
    if ! command -v pnpm &>/dev/null; then
        npm install -g pnpm --registry=https://registry.npmmirror.com
    fi
    pnpm install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir "$PNPM_STORE_DIR"
fi

echo ""
echo "==================================================="
echo "[Done] OpenClaw has been updated to the latest version!"
echo "For novice release packages, future updates should still prefer re-downloading the latest archive."
echo "You can now run ./start.sh to launch the system."
echo "==================================================="

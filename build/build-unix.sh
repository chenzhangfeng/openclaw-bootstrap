#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# 默认值
NODE_VERSION="22.22.1"
TARGET_OS="${1:-linux}"   # linux 或 darwin
TARGET_ARCH="${2:-x64}"   # x64 或 arm64
MODE="${3:-fat}"          # fat 或 slim

# Node.js 下载地址
case "$TARGET_OS-$TARGET_ARCH" in
  linux-x64)    NODE_PKG="node-v${NODE_VERSION}-linux-x64";;
  linux-arm64)  NODE_PKG="node-v${NODE_VERSION}-linux-arm64";;
  darwin-x64)   NODE_PKG="node-v${NODE_VERSION}-darwin-x64";;
  darwin-arm64) NODE_PKG="node-v${NODE_VERSION}-darwin-arm64";;
  *) echo "[ERROR] Unsupported: $TARGET_OS-$TARGET_ARCH"; exit 1;;
esac
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_PKG}.tar.xz"

DIST_NAME="openclaw-${TARGET_OS}-${TARGET_ARCH}-${MODE}"
DIST_DIR="${REPO_ROOT}/dist/${DIST_NAME}"

echo "=========================================="
echo "  OpenClaw Portable Builder - $TARGET_OS $TARGET_ARCH $MODE"
echo "=========================================="

# 清理旧产物
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# [1/6] 下载 Node.js
echo ""
echo "[1/6] Node.js v${NODE_VERSION} (${TARGET_OS}-${TARGET_ARCH})..."
CACHE_DIR="${REPO_ROOT}/build/cache"
mkdir -p "$CACHE_DIR"
if [ ! -f "${CACHE_DIR}/${NODE_PKG}.tar.xz" ]; then
    echo "Downloading..."
    curl -L -o "${CACHE_DIR}/${NODE_PKG}.tar.xz" "$NODE_URL"
fi
echo "Extracting..."
tar -xf "${CACHE_DIR}/${NODE_PKG}.tar.xz" -C "$DIST_DIR"
mv "${DIST_DIR}/${NODE_PKG}" "${DIST_DIR}/node"

# [2/6] 复制源码
echo ""
echo "[2/6] Copying OpenClaw source..."
if [ -d "${REPO_ROOT}/openclaw" ]; then
    cp -r "${REPO_ROOT}/openclaw" "${DIST_DIR}/openclaw"
    rm -rf "${DIST_DIR}/openclaw/.git"
else
    echo "[WARN] openclaw/ source not found!"
fi

# [3/6] 复制启动器和共享文件
echo ""
echo "[3/6] Copying launchers and shared files..."
LAUNCHERS_DIR="${REPO_ROOT}/launchers/unix"
if [ -d "$LAUNCHERS_DIR" ]; then
    cp "${LAUNCHERS_DIR}"/*.sh "${DIST_DIR}/" 2>/dev/null || true
    chmod +x "${DIST_DIR}"/*.sh 2>/dev/null || true
fi

PORTABLE_DIR="${REPO_ROOT}/portable"
if [ -d "$PORTABLE_DIR" ]; then
    cp -r "${PORTABLE_DIR}/scripts" "${DIST_DIR}/scripts"
    cp -r "${PORTABLE_DIR}/data" "${DIST_DIR}/data"
    [ -f "${PORTABLE_DIR}/README.md" ] && cp "${PORTABLE_DIR}/README.md" "${DIST_DIR}/"
fi

mkdir -p "${DIST_DIR}/browsers" "${DIST_DIR}/data/workspace"

# [4/6] 安装依赖 (fat 模式)
if [ "$MODE" = "fat" ]; then
    echo ""
    echo "[4/6] Installing dependencies (fat mode)..."
    export PATH="${DIST_DIR}/node/bin:$PATH"
    export npm_config_prefix="${DIST_DIR}/node"
    TEMP_STORE="${DIST_DIR}/temp-pnpm-store"
    export PNPM_STORE_DIR="$TEMP_STORE"

    cd "${DIST_DIR}/openclaw"
    npm install -g pnpm --registry=https://registry.npmmirror.com
    pnpm install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir "$TEMP_STORE"
    cd "$SCRIPT_DIR"

    # [5/6] 平台瘦身
    echo ""
    echo "[5/6] Pruning non-${TARGET_OS} packages..."
    "${DIST_DIR}/node/bin/node" "${SCRIPT_DIR}/prune-platform.js" \
        --platform "$TARGET_OS" --arch "$TARGET_ARCH" \
        --path "${DIST_DIR}/openclaw/node_modules"

    # 清理临时 store
    rm -rf "$TEMP_STORE"
    echo "Removed temp pnpm store"
else
    echo ""
    echo "[4/6] Skipping dependency install (slim mode)"
    echo "[5/6] Skipping platform prune (slim mode)"
fi

# [6/6] 完成
echo ""
echo "[6/6] Done!"
echo ""
echo "=========================================="
echo "Build complete: $DIST_NAME"
echo "Output: $DIST_DIR"
echo "=========================================="

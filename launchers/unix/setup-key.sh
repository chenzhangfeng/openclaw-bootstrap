#!/usr/bin/env bash
set -euo pipefail

echo "==================================================="
echo ""
echo "  OpenClaw - Compatibility Setup Wizard"
echo ""
echo "  If the product page already provides model/API settings,"
echo "  please configure it there first."
echo ""
echo "  This script is only a compatibility fallback."
echo ""
echo "==================================================="

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
NODE_DIR="$BASE_DIR/node"

if [ ! -f "$NODE_DIR/bin/node" ]; then
    echo "[ERROR] Node.js not found."
    exit 1
fi

echo ""
echo "Recommended path: run ./start.sh first, then configure model/API in the web UI."
echo "Only continue with this script if the current page has no config entry yet."
echo ""
echo "Select your AI provider:"
echo ""
echo "  [1] DeepSeek (Recommended)"
echo "  [2] OpenAI / ChatGPT"
echo "  [3] Qwen (Alibaba Cloud)"
echo "  [4] Yi (01.AI)"
echo "  [5] Moonshot (Kimi)"
echo "  [6] Ollama (Local, no key needed)"
echo "  [7] Other OpenAI-compatible provider"
echo ""
read -p "Enter number (1-7): " VENDOR_CHOICE

case "$VENDOR_CHOICE" in
  1) PROVIDER_NAME="deepseek"; BASE_URL="https://api.deepseek.com/v1";;
  2) PROVIDER_NAME="openai";   BASE_URL="https://api.openai.com/v1";;
  3) PROVIDER_NAME="qwen";     BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1";;
  4) PROVIDER_NAME="yi";       BASE_URL="https://api.lingyiwanwu.com/v1";;
  5) PROVIDER_NAME="moonshot";  BASE_URL="https://api.moonshot.cn/v1";;
  6)
    PROVIDER_NAME="ollama"
    BASE_URL="http://127.0.0.1:11434/v1"
    echo ""
    echo "[Info] Ollama mode: no API key needed."
    echo "placeholder" | "$NODE_DIR/bin/node" "$BASE_DIR/scripts/set-key.js" "$PROVIDER_NAME" "$BASE_URL"
    echo ""
    echo "==================================================="
    echo "  Compatibility config saved. Prefer the product page settings when available."
    echo "==================================================="
    exit 0
    ;;
  7)
    PROVIDER_NAME="custom"
    read -p "Enter API base URL (e.g. https://api.xxx.com/v1): " BASE_URL
    ;;
  *)
    echo "[ERROR] Invalid choice!"
    exit 1
    ;;
esac

echo ""
read -p "Paste your API key (e.g. sk-xxxxxxxxx): " API_KEY

if [ -z "$API_KEY" ]; then
    echo "[ERROR] API key cannot be empty!"
    exit 1
fi

echo ""
echo "[Configuring] Writing key to config..."
echo "$API_KEY" | "$NODE_DIR/bin/node" "$BASE_DIR/scripts/set-key.js" "$PROVIDER_NAME" "$BASE_URL"

echo ""
echo "==================================================="
echo "  Compatibility config saved. Prefer the product page settings when available."
echo "==================================================="

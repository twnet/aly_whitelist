#!/usr/bin/env bash
set -euo pipefail

# 加密 whitelist.json 并提交到 Git
# 用法: ./auto_update.sh [commit message]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. 校验 JSON 格式
echo "▶ 校验 whitelist.json ..."
if ! "$SCRIPT_DIR/verify_json.sh" "$SCRIPT_DIR/whitelist.json"; then
    echo "✗ JSON 校验失败，终止" >&2
    exit 1
fi

# 2. 加密
echo "▶ 加密 whitelist.json → whitelist.enc ..."
"$SCRIPT_DIR/encrypter.sh"

# 3. Git 操作
echo "▶ 提交到 Git ..."
cd "$SCRIPT_DIR"
git add whitelist.enc
MESSAGE="${1:-auto: update whitelist.enc $(date +'%m%d-%H%M%S')}"
git commit -m "$MESSAGE"
git push

echo "✓ 完成"

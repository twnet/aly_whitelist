#!/usr/bin/env bash
set -euo pipefail

# 解密 whitelist.enc → stdout
# 用法: ./decrypter.sh [输入文件]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="${1:-$SCRIPT_DIR/whitelist.enc}"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "错误: .env 文件不存在" >&2
    exit 1
fi

source "$ENV_FILE"

if [ -z "${ENCRYPTION_PASSWORD:-}" ]; then
    echo "错误: ENCRYPTION_PASSWORD 未设置" >&2
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "错误: 输入文件 $INPUT 不存在" >&2
    exit 1
fi

openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -salt \
    -in "$INPUT" \
    -pass "pass:$ENCRYPTION_PASSWORD"

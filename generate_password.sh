#!/usr/bin/env bash
set -euo pipefail

# 生成 32 位随机强密码
# 用法: ./generate_password.sh [长度，默认32]

LENGTH="${1:-32}"

if command -v openssl &>/dev/null; then
    openssl rand -base64 "$((LENGTH * 3 / 4 + 1))" | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' | head -c "$LENGTH"
    echo
else
    echo "错误: 需要 openssl" >&2
    exit 1
fi

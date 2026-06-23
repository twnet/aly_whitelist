#!/usr/bin/env bash
set -euo pipefail

# 校验 whitelist.json 格式是否正确
# 用法: ./verify_json.sh [whitelist.json]

JSON_FILE="${1:-$(dirname "$0")/whitelist.json}"

# 1. 语法校验
if ! jq empty "$JSON_FILE" 2>/dev/null; then
    echo "失败: JSON 语法错误" >&2
    exit 1
fi

# 2. 结构校验
SCHEMA_ERRORS=$(jq -r '
  if .version == null then "缺少 version 字段" else empty end,
  if .sources == null then "缺少 sources 字段" else empty end,
  if .sources.domains != null then
    (.sources.domains | to_entries | .[] |
      if .value.value == null or .value.value == "" then
        "domains[\(.key)].value 无效: \(.value)"
      else empty end
    )
  else empty end,
  if .sources.ips != null then
    (.sources.ips | to_entries | .[] |
      if .value.value == null or .value.value == ""
         or (.value.value | test("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$") | not) then
        "ips[\(.key)].value 无效: \(.value)"
      else empty end
    )
  else empty end
' "$JSON_FILE" 2>/dev/null)

if [ -n "$SCHEMA_ERRORS" ]; then
    echo "失败: JSON 结构异常" >&2
    echo "$SCHEMA_ERRORS" >&2
    exit 1
fi

echo "通过: $JSON_FILE 格式正确"

#!/bin/bash
# MCP Worker 起動スクリプト
# Usage: run_worker.sh <request_id> <mcp_names> <task>
#   request_id: リクエスト識別子
#   mcp_names:  使用するMCP設定名（スペース区切りで複数指定可、例: "github slack"）
#   task:       実行するタスク内容

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 引数チェック
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <request_id> <mcp_names> <task>" >&2
    echo "  request_id: Request identifier" >&2
    echo "  mcp_names:  MCP config names (space-separated, e.g., 'github slack')" >&2
    echo "  task:       Task description" >&2
    exit 1
fi

REQUEST_ID="$1"
MCP_NAMES="$2"
TASK="$3"

# パス設定
MCP_CONFIGS_DIR="${SKILL_DIR}/mcp-configs"
SCHEMA_FILE="${SKILL_DIR}/schema.worker-result.json"
SYSTEM_PROMPT_FILE="${SKILL_DIR}/prompts/worker-system.md"

# 一時ファイル
MERGED_MCP_CONFIG=$(mktemp /tmp/mcp-worker-config-XXXXXX.json)
trap "rm -f '$MERGED_MCP_CONFIG'" EXIT

# MCP設定をマージ
merge_mcp_configs() {
    local configs=()
    for name in $MCP_NAMES; do
        local config_file="${MCP_CONFIGS_DIR}/${name}.json"
        if [[ -f "$config_file" ]]; then
            configs+=("$config_file")
        else
            echo "Warning: MCP config not found: $config_file" >&2
        fi
    done

    if [[ ${#configs[@]} -eq 0 ]]; then
        # 設定がない場合は空のMCP設定
        echo '{"mcpServers":{}}' > "$MERGED_MCP_CONFIG"
    elif [[ ${#configs[@]} -eq 1 ]]; then
        # 1つだけならそのままコピー
        cp "${configs[0]}" "$MERGED_MCP_CONFIG"
    else
        # 複数の場合はマージ（Python使用）
        python3 -c "
import json
import sys

merged = {'mcpServers': {}}
for path in sys.argv[1:]:
    with open(path) as f:
        data = json.load(f)
        merged['mcpServers'].update(data.get('mcpServers', {}))

print(json.dumps(merged))
" "${configs[@]}" > "$MERGED_MCP_CONFIG"
    fi
}

# システムプロンプトを読み込み
read_system_prompt() {
    if [[ -f "$SYSTEM_PROMPT_FILE" ]]; then
        cat "$SYSTEM_PROMPT_FILE"
    else
        echo "You are an MCP Worker. Output only valid JSON matching the schema."
    fi
}

# JSON Schemaを一行化
get_schema_oneline() {
    python3 -c "import json; print(json.dumps(json.load(open('$SCHEMA_FILE'))))"
}

# MCP設定をマージ
merge_mcp_configs

# プロンプト構築
FULL_PROMPT="request_id: ${REQUEST_ID}

Task:
${TASK}"

SYSTEM_PROMPT=$(read_system_prompt)
SCHEMA_ONELINE=$(get_schema_oneline)

# Worker Claude を起動
# ビルトインツールは読み取り系のみ許可（MCPツールは --mcp-config で許可）
# --chrome: Claude Code標準搭載のChrome DevToolsを有効化
RESPONSE=$(claude -p "$FULL_PROMPT" \
    --system-prompt "$SYSTEM_PROMPT" \
    --strict-mcp-config \
    --mcp-config "$MERGED_MCP_CONFIG" \
    --json-schema "$SCHEMA_ONELINE" \
    --output-format json \
    --chrome \
    --allowedTools "Read,Glob,Grep")

# structured_output フィールドを抽出して出力
echo "$RESPONSE" | python3 -c "
import json
import sys
data = json.load(sys.stdin)
if 'structured_output' in data:
    print(json.dumps(data['structured_output'], indent=2))
else:
    print(json.dumps(data, indent=2))
"

#!/bin/bash
# Math Explorer Worker - 横断的数理探索タスク実行スクリプト
# Usage: run_explorer.sh <request_id> <mode> <content_file>
#   request_id:   リクエスト識別子
#   mode:         map | bridge | formalize | survey
#   content_file: 探索対象の記述ファイルのパス（Markdown）

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 引数チェック
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <request_id> <mode> <content_file>" >&2
    echo "  request_id:   Request identifier (e.g., explore_20260208-120000)" >&2
    echo "  mode:         map | bridge | formalize | survey" >&2
    echo "  content_file: Path to exploration content file (Markdown)" >&2
    exit 1
fi

REQUEST_ID="$1"
MODE="$2"
CONTENT_FILE="$3"

# モードの検証
if [[ ! "$MODE" =~ ^(map|bridge|formalize|survey)$ ]]; then
    echo "Error: Invalid mode '$MODE'. Must be one of: map, bridge, formalize, survey" >&2
    exit 1
fi

# コンテンツファイルの存在チェック
if [[ ! -f "$CONTENT_FILE" ]]; then
    echo "Error: Content file not found: $CONTENT_FILE" >&2
    exit 1
fi

# パス設定
SCHEMA_FILE="${SKILL_DIR}/schema.explorer-result.json"
SYSTEM_PROMPT_FILE="${SKILL_DIR}/prompts/explorer-system.md"
SETTINGS_FILE="${SKILL_DIR}/settings.json"

# 必須ファイルの存在チェック
for f in "$SCHEMA_FILE" "$SYSTEM_PROMPT_FILE" "$SETTINGS_FILE"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: Required file not found: $f" >&2
        exit 1
    fi
done

# システムプロンプトを読み込み
read_system_prompt() {
    cat "$SYSTEM_PROMPT_FILE"
}

# JSON Schemaを一行化
get_schema_oneline() {
    python3 -c "import json; print(json.dumps(json.load(open('$SCHEMA_FILE'))))"
}

# コンテンツを読み込み
read_content() {
    cat "$CONTENT_FILE"
}

# モード別の指示を生成
get_mode_instructions() {
    case "$MODE" in
        map)
            echo "## 指示: 現象→フレームワーク対応分析モード
与えられた現象の記述を精読し、背後にある数理構造を探索してください。
複数の分野から関連するフレームワークを網羅的に列挙し、各接続の確度を判定してください。"
            ;;
        bridge)
            echo "## 指示: 横断的アナロジー分析モード
与えられた2つ以上の概念・分野について、共通する数理構造を特定してください。
転用可能な技法と既知の成功例を具体的に挙げ、分野横断的な接続を構築してください。"
            ;;
        formalize)
            echo "## 指示: 定式化提案モード
与えられた非形式的な観察・仮説を精読し、複数の数学的定式化オプションを提案してください。
各オプションの利点・限界を分析し、既存理論との接続点を特定してください。"
            ;;
        survey)
            echo "## 指示: サーベイレポートモード
与えられたトピックの数理的アプローチを俯瞰的にサーベイしてください。
歴史的発展、主要な貢献、現在のフロンティア、分野横断的な影響を整理してください。"
            ;;
    esac
}

# プロンプト構築
CONTENT=$(read_content)
FULL_PROMPT="# 横断的数理探索タスク

## リクエスト情報
- request_id: ${REQUEST_ID}
- mode: ${MODE}

## 探索対象

${CONTENT}

$(get_mode_instructions)"

SYSTEM_PROMPT=$(read_system_prompt)
SCHEMA_ONELINE=$(get_schema_oneline)

# Worker Claude を起動
RESPONSE=$(claude -p "$FULL_PROMPT" \
    --system-prompt "$SYSTEM_PROMPT" \
    --json-schema "$SCHEMA_ONELINE" \
    --output-format json \
    --settings "$SETTINGS_FILE" \
    --max-turns 30 \
    2>/dev/null)

# structured_output フィールドを抽出して出力
echo "$RESPONSE" | python3 -c "
import json
import sys

try:
    data = json.load(sys.stdin)
    if 'structured_output' in data:
        print(json.dumps(data['structured_output'], indent=2))
    else:
        print(json.dumps(data, indent=2))
except json.JSONDecodeError as e:
    error_response = {
        'request_id': '${REQUEST_ID}',
        'mode': '${MODE}',
        'status': 'blocked',
        'topic': 'unknown',
        'result': {
            'summary': f'Worker output parsing failed: {str(e)}',
            'frameworks_found': [],
            'cross_field_bridges': [],
            'open_questions': [],
            'visualization_suggestions': []
        },
        'confidence_notes': 'Worker output could not be parsed',
        'further_directions': ['Retry the worker'],
        'artifacts_created': [],
        'next_action': 'blocked'
    }
    print(json.dumps(error_response, indent=2))
"

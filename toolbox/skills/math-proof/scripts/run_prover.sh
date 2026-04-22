#!/bin/bash
# Math Proof Worker - 数学証明分析タスク実行スクリプト
# Usage: run_prover.sh <request_id> <mode> <math_content_file>
#   request_id:       リクエスト識別子
#   mode:             verify | construct | explore | formalize
#   math_content_file: 数学コンテンツファイルのパス

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 引数チェック
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <request_id> <mode> <math_content_file>" >&2
    echo "  request_id:       Request identifier (e.g., proof_20260208-120000)" >&2
    echo "  mode:             verify | construct | explore | formalize" >&2
    echo "  math_content_file: Path to math content file" >&2
    exit 1
fi

REQUEST_ID="$1"
MODE="$2"
MATH_CONTENT_FILE="$3"

# モードの検証
if [[ ! "$MODE" =~ ^(verify|construct|explore|formalize)$ ]]; then
    echo "Error: Invalid mode '$MODE'. Must be one of: verify, construct, explore, formalize" >&2
    exit 1
fi

# コンテンツファイルの存在チェック
if [[ ! -f "$MATH_CONTENT_FILE" ]]; then
    echo "Error: Math content file not found: $MATH_CONTENT_FILE" >&2
    exit 1
fi

# パス設定
SCHEMA_FILE="${SKILL_DIR}/schema.prover-result.json"
SYSTEM_PROMPT_FILE="${SKILL_DIR}/prompts/proof-system.md"
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

# 数学コンテンツを読み込み
read_math_content() {
    cat "$MATH_CONTENT_FILE"
}

# モード別の指示を生成
get_mode_instructions() {
    case "$MODE" in
        verify)
            echo "## 指示: 証明検証モード
与えられた証明を精読し、各ステップの論理的妥当性を検証してください。
ギャップ・誤謬・循環論法を特定し、検証レポートを作成してください。"
            ;;
        construct)
            echo "## 指示: 証明構築モード
与えられた定理・命題の証明をゼロから構築してください。
適用可能な証明技法を検討し、最適な戦略で証明を完成させてください。"
            ;;
        explore)
            echo "## 指示: 概念探索モード
与えられた概念・定理の関連事項を調査してください。
関連定理、一般化・特殊化の方向性、前提と帰結の関係を整理してください。"
            ;;
        formalize)
            echo "## 指示: 形式化モード
与えられた自然言語の証明を形式的な証明に変換してください。
すべての推論規則を明示し、形式体系での記述を完成させてください。"
            ;;
    esac
}

# プロンプト構築
MATH_CONTENT=$(read_math_content)
FULL_PROMPT="# 数学証明分析タスク

## リクエスト情報
- request_id: ${REQUEST_ID}
- mode: ${MODE}

## 数学コンテンツ

${MATH_CONTENT}

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
            'techniques_used': [],
            'assumptions': []
        },
        'issues_found': [{'type': 'error', 'location': 'output', 'description': 'Worker did not return valid JSON', 'severity': 'critical', 'suggestion': 'Retry the worker'}],
        'artifacts_created': [],
        'next_action': 'blocked'
    }
    print(json.dumps(error_response, indent=2))
"

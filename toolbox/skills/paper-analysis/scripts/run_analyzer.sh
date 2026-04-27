#!/bin/bash
# Paper Analysis Worker - 論文分析タスク実行スクリプト
# Usage: run_analyzer.sh <request_id> <mode> <paper_file>
#   request_id:  リクエスト識別子
#   mode:        analyze | methodology | statistics | claims
#   paper_file:  論文ファイルのパス（PDF or Markdown）

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 引数チェック
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <request_id> <mode> <paper_file>" >&2
    echo "  request_id:  Request identifier (e.g., paper_20260208-120000)" >&2
    echo "  mode:        analyze | methodology | statistics | claims" >&2
    echo "  paper_file:  Path to paper file (PDF or Markdown)" >&2
    exit 1
fi

REQUEST_ID="$1"
MODE="$2"
PAPER_FILE="$3"

# モードの検証
if [[ ! "$MODE" =~ ^(analyze|methodology|statistics|claims)$ ]]; then
    echo "Error: Invalid mode '$MODE'. Must be one of: analyze, methodology, statistics, claims" >&2
    exit 1
fi

# ペーパーファイルの存在チェック
if [[ ! -f "$PAPER_FILE" ]]; then
    echo "Error: Paper file not found: $PAPER_FILE" >&2
    exit 1
fi

# パス設定
SCHEMA_FILE="${SKILL_DIR}/schema.analyzer-result.json"
SYSTEM_PROMPT_FILE="${SKILL_DIR}/prompts/analyzer-system.md"
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

# モード別の指示を生成
get_mode_instructions() {
    case "$MODE" in
        analyze)
            echo "## 指示: 全体分析モード
論文全体の構造・主張・エビデンスを抽出し、包括的な分析レポートを作成してください。
研究の目的、主要な主張、エビデンスの強さ、方法論の概要を評価してください。"
            ;;
        methodology)
            echo "## 指示: 方法論評価モード
研究デザイン、サンプリング、変数の操作化、交絡変数の統制を批判的に評価してください。
内的妥当性・外的妥当性の観点から方法論の強みと弱みを報告してください。"
            ;;
        statistics)
            echo "## 指示: 統計分析モード
使用された統計手法の適切性、前提条件の充足、検定力、効果量を評価してください。
p-hacking、HARKing、多重比較の問題を含む統計的誤謬をチェックしてください。"
            ;;
        claims)
            echo "## 指示: Claims-Evidence マッピングモード
論文のすべての主張を抽出し、種類（事実/推論/意見/仮説）に分類してください。
各主張を支持するエビデンスを特定し、対応関係をマッピングしてください。"
            ;;
    esac
}

# プロンプト構築
FULL_PROMPT="# 論文分析タスク

## リクエスト情報
- request_id: ${REQUEST_ID}
- mode: ${MODE}
- paper_file: ${PAPER_FILE}

## 指示
以下の論文ファイルを Read ツールで読み込んで分析してください。
PDF ファイルの場合は Read ツールで直接読み込めます。

論文ファイルパス: ${PAPER_FILE}

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
        'paper_info': {'title': 'unknown'},
        'result': {
            'summary': f'Worker output parsing failed: {str(e)}',
            'strengths': [],
            'limitations': []
        },
        'issues_found': [{'type': 'reporting', 'location': 'output', 'description': 'Worker did not return valid JSON', 'severity': 'critical', 'suggestion': 'Retry the worker'}],
        'artifacts_created': [],
        'next_action': 'blocked'
    }
    print(json.dumps(error_response, indent=2))
"

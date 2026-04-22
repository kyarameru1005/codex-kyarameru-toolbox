#!/bin/bash
# Chrome Worker 起動スクリプト（expect版 - インタラクティブモード）
# Usage: run_worker.sh <request_id> <task>
#   request_id: リクエスト識別子
#   task:       実行するブラウザタスク内容

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 引数チェック
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <request_id> <task>" >&2
    echo "  request_id: Request identifier" >&2
    echo "  task:       Browser task description" >&2
    exit 1
fi

REQUEST_ID="$1"
TASK="$2"

# パス設定
OUTPUT_FILE="/tmp/chrome-worker-result-${REQUEST_ID}.json"

# プロンプトをファイルに書き出し（1行で）
PROMPT_FILE="/tmp/chrome-worker-prompt-${REQUEST_ID}.txt"
echo "request_id: ${REQUEST_ID} | Task: ${TASK} | 完了したら結果を ${OUTPUT_FILE} にJSON形式で書き出し、/exit で終了してください。" > "$PROMPT_FILE"

# expectスクリプトをファイルに書き出し
EXPECT_SCRIPT="/tmp/chrome-worker-expect-${REQUEST_ID}.exp"
cat > "$EXPECT_SCRIPT" << 'EXPECT_EOF'
#!/usr/bin/expect -f
set timeout 300
set prompt_file [lindex $argv 0]

# プロンプトファイルを読み込み（改行を削除）
set fp [open $prompt_file r]
set prompt_content [string trim [read $fp]]
close $fp

# Claudeをインタラクティブモードで起動（--chrome有効、許可プロンプトをスキップ）
spawn claude --chrome --dangerously-skip-permissions

# 初回表示を待つ（Bypass Permissions の確認含む）
expect {
    "Yes, I accept" {
        # Bypass Permissions の確認 - 下矢印で2番目を選択してEnter
        sleep 0.5
        send "\033\[B"
        sleep 0.3
        send "\r"
        exp_continue
    }
    "Press Enter" {
        send "\r"
        exp_continue
    }
    -re {Welcome} {
        sleep 3
    }
    timeout {
        puts stderr "Timeout waiting for Claude"
        exit 1
    }
}

# プロンプトを送信
send "$prompt_content"
sleep 0.5
send "\r"

# 処理完了を待つ（許可プロンプトには自動でYesを選択）
expect {
    "Do you want to proceed?" {
        # Yesを選択（そのままEnter）
        sleep 0.3
        send "\r"
        exp_continue
    }
    "Yes, and don't ask again" {
        # 下矢印で2番目を選択してEnter
        sleep 0.3
        send "\033\[B"
        sleep 0.2
        send "\r"
        exp_continue
    }
    -re {Allow once} {
        sleep 0.3
        send "\r"
        exp_continue
    }
    -re {Allow for this project} {
        # 下矢印で選択してEnter
        sleep 0.3
        send "\033\[B"
        sleep 0.2
        send "\r"
        exp_continue
    }
    eof {
        # 正常終了
    }
    "Goodbye" {
        # 正常終了
    }
    timeout {
        puts stderr "Timeout waiting for task completion"
        exit 1
    }
}
EXPECT_EOF

chmod +x "$EXPECT_SCRIPT"

# expectスクリプトを実行
"$EXPECT_SCRIPT" "$PROMPT_FILE"

# 一時ファイルを削除
rm -f "$PROMPT_FILE" "$EXPECT_SCRIPT"

# 結果ファイルを読み込んで出力
if [[ -f "$OUTPUT_FILE" ]]; then
    cat "$OUTPUT_FILE"
    rm -f "$OUTPUT_FILE"
else
    echo "{\"request_id\": \"$REQUEST_ID\", \"status\": \"error\", \"summary\": \"結果ファイルが生成されませんでした\", \"answer_markdown\": \"Chrome Workerがタスクを完了しましたが、結果ファイルが見つかりませんでした。\"}"
    exit 1
fi

# Chrome Worker リファレンス

## アーキテクチャ

```
Main Claude → chrome-worker skill → Worker Claude (--chrome) → Chrome Browser
                                  ↓
                         JSON Schema検証済み出力
```

## スクリプト詳細

### run_worker.sh

場所: `scripts/run_worker.sh`

**実行コマンド:**
```bash
claude -p "$PROMPT" \
    --system-prompt "$SYSTEM_PROMPT" \
    --json-schema "$SCHEMA" \
    --output-format json \
    --chrome \
    --allowedTools "Read,Glob,Grep"
```

**フラグの説明:**
| フラグ | 目的 |
|--------|------|
| `-p` | 非対話モードでプロンプト実行 |
| `--chrome` | Chrome拡張機能との連携を有効化 |
| `--json-schema` | JSON出力形式を強制 |
| `--output-format json` | JSON形式で出力 |
| `--allowedTools` | 許可するビルトインツール |

## 要件

### ソフトウェア要件
- Google Chrome（可視ウィンドウ必須）
- Claude in Chrome 拡張機能 v1.0.36+
- Claude Code CLI v2.0.73+
- 有料Claudeプラン（Pro, Team, Enterprise）

### 確認コマンド
```bash
# Claude Code バージョン確認
claude --version

# 更新
claude update
```

## 出力スキーマ

完全なJSON Schemaは [schema.worker-result.json](schema.worker-result.json) を参照。

### 成功レスポンス

```json
{
  "request_id": "req_20241231-120000",
  "status": "success",
  "summary": "ログインフォームのUI確認完了",
  "answer_markdown": "## 確認結果\n\n- ボタン配置: OK\n- フォームバリデーション: OK",
  "screenshots": ["/tmp/login-form.gif"],
  "console_errors": [],
  "sources": ["https://example.com/login"]
}
```

### エラーレスポンス

```json
{
  "request_id": "req_20241231-120000",
  "status": "error",
  "summary": "Chrome拡張機能に接続できませんでした",
  "answer_markdown": "## エラー詳細\n\nChrome拡張機能が検出されませんでした...",
  "error_message": "Chrome extension not detected"
}
```

## 制限事項

| 制限 | 説明 |
|------|------|
| 可視ウィンドウ必須 | ヘッドレスモード非対応 |
| Chrome限定 | Brave, Arc等は非対応 |
| WSL非対応 | Windows Subsystem for Linuxでは動作しない |
| モーダルダイアログ | alert/confirm/promptはブロックする |

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| 拡張機能未検出 | 拡張機能未インストール | Chrome拡張機能v1.0.36+をインストール |
| 接続エラー | Chromeが起動していない | Chromeを起動してから再実行 |
| タイムアウト | ブラウザ応答なし | モーダルダイアログを手動で閉じる |
| 権限エラー | 初回セットアップ未完了 | Chromeを再起動 |

## 使用例

### UIデザイン確認
```bash
bash ~/.claude/skills/chrome-worker/scripts/run_worker.sh \
  "req_$(date +%Y%m%d-%H%M%S)" \
  "https://example.com/dashboard を開いて、ナビゲーションバーのレイアウトを確認してください"
```

### フォームテスト
```bash
bash ~/.claude/skills/chrome-worker/scripts/run_worker.sh \
  "req_$(date +%Y%m%d-%H%M%S)" \
  "https://example.com/signup のフォームに無効なメールアドレスを入力し、バリデーションエラーが表示されることを確認してください"
```

### コンソールエラー監視
```bash
bash ~/.claude/skills/chrome-worker/scripts/run_worker.sh \
  "req_$(date +%Y%m%d-%H%M%S)" \
  "https://example.com を開いてコンソールのエラーを収集してください"
```

## mcp-worker との違い

| 項目 | mcp-worker | chrome-worker |
|------|------------|---------------|
| 用途 | 外部API連携（GitHub等） | ブラウザUI操作 |
| 実行方式 | ヘッドレス（-p） | Chrome連携（--chrome） |
| 要件 | MCP設定ファイル | Chrome + 拡張機能 |
| 対応環境 | サーバー/CI可 | デスクトップのみ |

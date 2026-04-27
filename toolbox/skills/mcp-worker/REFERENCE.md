# MCP Worker リファレンス

## アーキテクチャ

```
Main Claude (MCPなし) → mcp-worker skill → Worker Claude (MCPあり) → MCP Servers
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
    --strict-mcp-config \
    --mcp-config "$MERGED_MCP_CONFIG" \
    --json-schema "$SCHEMA" \
    --max-turns 6 \
    --permission-mode bypassPermissions \
    --no-markdown
```

**フラグの説明:**
| フラグ | 目的 |
|--------|------|
| `-p` | 非対話モードでプロンプト実行 |
| `--strict-mcp-config` | 指定したMCP設定のみ使用 |
| `--mcp-config` | MCP設定ファイルのパス |
| `--json-schema` | JSON出力形式を強制 |
| `--max-turns 6` | 会話ターン数を制限 |
| `--permission-mode bypassPermissions` | 許可プロンプトをスキップ |
| `--no-markdown` | 生出力（マークダウン装飾なし） |

## MCP設定ファイル形式

`mcp-configs/` 内の各設定ファイルは以下の構造:

```json
{
  "mcpServers": {
    "<サーバー名>": {
      "command": "<実行ファイル>",
      "args": ["<引数1>", "<引数2>"],
      "env": {
        "<環境変数名>": "${環境変数名}"
      }
    }
  }
}
```

**1つのファイルに複数サーバーを定義可能**

### 設定のマージ

複数のMCP名を指定した場合（例: `"github slack"`）、スクリプトは:
1. `mcp-configs/` から各 `<name>.json` を読み込み
2. すべての `mcpServers` オブジェクトをマージ
3. 一時的な統合設定ファイルを作成

## 出力スキーマ

完全なJSON Schemaは [schema.worker-result.json](schema.worker-result.json) を参照。

### 成功レスポンス

```json
{
  "request_id": "req_20241231-120000",
  "status": "success",
  "summary": "リポジトリに3件のオープンissueを発見",
  "answer_markdown": "## オープンissue\n\n1. ログインのバグ...",
  "sources": ["https://github.com/org/repo/issues"]
}
```

### エラーレスポンス

```json
{
  "request_id": "req_20241231-120000",
  "status": "error",
  "summary": "GitHub APIへのアクセスに失敗",
  "answer_markdown": "## エラー詳細\n\n認証に失敗しました...",
  "error_message": "401 Unauthorized"
}
```

## セキュリティに関する注意

- **APIキーをコミットしない** - 環境変数を使用すること
- `--permission-mode bypassPermissions` はすべてのプロンプトをスキップ - 本番環境では要調整
- `--max-turns 6` で暴走を防止

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| ワーカーがハング | 許可プロンプト待ち | `--permission-mode` を確認 |
| JSON出力が無効 | スキーマ不一致 | `--json-schema` フラグを確認 |
| MCPが見つからない | 設定パスが間違い | `mcp-configs/<name>.json` の存在を確認 |
| 認証エラー | 環境変数未設定 | 必要な環境変数をexportする |

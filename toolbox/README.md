# toolbox 構成ガイド

`toolbox/` は `~/.codex` に配備する資材のソースを置く場所です。

## 配備対象（管理対象）

- `AGENTS.md`
- `agents/`
- `hooks/`
- `mcp/`
- `prompts/`
- `scripts/`
- `skills/`
- `vendor_imports/`
- `harness/`（ハーネス定義）

## 実行時生成物（管理対象外）

以下は実行時に生成されるため、Git管理しません。

- `.codex/`
- `.tmp/`
- `log/`
- `sessions/`
- `shell_snapshots/`
- `sqlite/`
- `tmp/`

## harness の役割

`toolbox/harness/` には、ハーネスの入力・設定・出力仕様を置きます。
実行エントリは `scripts/` 側から呼び出す想定です。

# agents

このディレクトリは、研究用の開発ハーネスで使うサブエージェント定義を置く場所です。
各 `*.toml` は 1 つのエージェント設定を表し、名前、役割、使用モデル、推論強度、sandbox 権限、開発者向け指示を持ちます。

## 役割一覧

| ファイル | 主な役割 |
| --- | --- |
| `zeus.toml` | 全体判断を行うマネージャ |
| `hermes.toml` | 実装前の調査 |
| `daedalus.toml` | 設計・アーキテクチャ整理 |
| `hephaestus.toml` | 実装担当 |
| `athena.toml` | 実装後レビュー |
| `themis.toml` | テスト・評価 |
| `ares.toml` | セキュリティ・リスク確認 |
| `apollo.toml` | README や設計メモなどの文書化 |
| `chronos.toml` | ログ整理と振り返り |

## ファイルの見方

各設定ファイルには主に次の項目があります。

- `name`: エージェント名
- `description`: 短い役割説明
- `model`: 使用モデル
- `model_reasoning_effort`: 推論の強さ
- `sandbox_mode`: `read-only` / `workspace-write` などの実行権限
- `developer_instructions`: そのエージェント専用の行動指針と出力形式

## 運用の考え方

- `Zeus` は最初に使う判断役です。軽い整理は自分で行い、必要に応じて他エージェントの利用を決めます。
- `Hermes` → `Daedalus` → `Hephaestus` の順で、調査・設計・実装を分離できます。
- 実装後は `Athena` や `Themis` で、レビューと検証を分けて扱えます。
- 文書化や研究記録が必要な場合は `Apollo` と `Chronos` を使います。

## 注意点

- `workspace-write` のエージェントは書き込み可能なので、実装や文書更新を担います。
- `read-only` のエージェントは調査、判断、レビュー向けです。
- 役割分離が前提なので、定義を変えるときは責務が混ざらないか確認してください。

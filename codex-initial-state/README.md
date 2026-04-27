# codex-initial-state

このディレクトリは、`~/.codex` を「公式ドキュメント上の初期状態に近い最小構成」へ戻すための復元元です。

## 収録方針

- `config.toml` のみを置く（最小構成）。
- 追加設定は入れず、Codex のビルトイン既定値を使う。

## 根拠（2026-04-22 確認）

- Config Basics: ユーザー設定は `~/.codex/config.toml` で管理する記載。
- Sample Configuration: 必要なキーだけを入れる運用が前提の記載。
- Config Reference: 多くの項目は未設定時に既定値が適用される記載。

参照:
- https://developers.openai.com/codex/config-basic
- https://developers.openai.com/codex/config-sample
- https://developers.openai.com/codex/config-reference

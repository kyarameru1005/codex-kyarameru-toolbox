# Understanding Check

変更前後に、次の観点を確認する。

## 変更前

- 参照順序を守ったか。`AGENTS.md` -> `README.md` -> `docs/`
- 既存の検証コマンドを確認したか。
- 変更対象が `toolbox/` 本体なのか、運用文書なのかを切り分けたか。

## 変更後

- 変更内容が `AGENTS.md` の安全ルールに反していないか。
- 追加した文書が既存文書と重複せず、入口または詳細のどちらかに役割分担されているか。
- `ai_log/` に置くべき内容と PR 本文に残すべき内容を混同していないか。
- 実行した検証と未実行理由を説明できるか。

## 報告時の確認

以下の見出しを最低限含める。

- `Summary`
- `Created files`
- `Updated files`
- `Skipped files`
- `Validation`
- `Human review points`
- `Next actions`

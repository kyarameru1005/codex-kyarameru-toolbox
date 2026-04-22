---
name: skill-validation-worker
description: 新規/更新したスキルが運用基準を満たすかを実装前後で一貫して検証する
---

# skill-validation-worker

目的: 新規/更新したスキルが運用基準を満たすかを、実装前後で一貫して検証する。

## 推奨トリガー

- 新しいスキルディレクトリを追加したとき
- 既存 `SKILL.md` / `scripts/` / `references/` を更新したとき
- PR前にスキル品質を短時間で確認したいとき

## 入力テンプレート

- 対象スキル: `toolbox/skills/<skill-name>`
- 変更種別: 追加 / 更新 / 廃止
- 検証範囲: `structure` / `script` / `policy` / `all`
- 完了条件: PRに貼る検証結果を出力できること

## 実行手順

1. 構造チェック
   - `SKILL.md` 存在
   - `scripts/` と `references/` は必要時のみ存在
   - ファイル名が kebab-case を満たす
2. 内容チェック
   - `SKILL.md` に `目的`、`推奨トリガー`、`出力` がある
   - 曖昧表現を避ける
3. スクリプトチェック（存在時）
   - `shellcheck` 相当の最低限チェック（`bash -n`）
   - 実行権限が必要なスクリプトは `chmod +x` を確認
4. リポジトリ整合
   - `README.md` の同梱内容と齟齬がないか確認
   - 変更がある場合は `scripts/policy-check.sh` / テストを更新

## 主要コマンド

```bash
bash toolbox/skills/skill-validation-worker/scripts/check-skill.sh toolbox/skills/<skill-name>
.venv/bin/python -m pytest -q
bash scripts/policy-check.sh
```

## 出力

- 検証サマリ（対象、実行コマンド、成否）
- 失敗時の原因（ファイル/行/ルール）
- 修正提案（最小修正手順）

## 出力例

```md
## 検証サマリ
- 対象: `toolbox/skills/example-worker`
- 実行: `check-skill.sh` / `pytest -q`
- 成否: pass

## 確認結果
- `SKILL.md` 必須セクションあり
- スクリプト構文エラーなし
- README 同梱内容と整合
```

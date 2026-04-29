# Harness Report (2026-04-29 13:54:15) - bootstrap-repository-pr

## 結論
- リポジトリ標準構造を `bootstrap-repository` 基準へ寄せ、AGENTS 運用・入口文書・検証スクリプトの参照先を整理した。

## 実施内容
- `toolbox/skills/agents-md-writer` を `toolbox/skills/bootstrap-repository` へ再編し、`check-agents-md.sh` と `check-repository-layout.sh` を配置した。
- `AGENTS.md` と `toolbox/AGENTS.md` を更新し、変更可能範囲、報告フォーマット、Done 条件、外部反映時の扱いを明文化した。
- `README.md`、`docs/repository-layout.md`、`docs/harness-spec.md` を更新し、標準構造、orchestrator 導線、検証順序、レポート記録ルールを整合させた。
- `docs/overview.md`、`docs/architecture.md`、`docs/requirements.md`、`docs/understanding-check.md`、`ai_log/README.md`、`tests/README.md` を追加し、入口文書と補助ディレクトリの責務を分離した。
- `scripts/policy-check.sh`、`scripts/finish-pr.sh`、`tests/test_install.py`、`toolbox/skills/git-pr-worker/SKILL.md` を更新し、リネーム後のスクリプト参照と検証観点を追随させた。

## 課題
- `toolbox/AGENTS.md` を `~/.codex/AGENTS.md` へ反映する `python3 scripts/install.py update` は、リポジトリ外変更になるため未実施。
- GitHub への push / PR 作成は、この後のブランチ作成・コミット・認証状態に依存する。

## 次アクション
- 検証通過後に作業ブランチを切り、commit / push / PR 作成まで進める。

## 検証
- 実行コマンド: `bash scripts/policy-check.sh`
- 結果: 成功
- 実行コマンド: `.venv/bin/python -m pytest -q`
- 結果: 25 passed
- 実行コマンド: `bash scripts/harness.sh --quick`
- 結果: 成功

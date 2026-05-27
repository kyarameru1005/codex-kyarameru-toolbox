# Distribution Task List

このリポジトリを他の人へ配布できる状態にするためのタスクリスト。
`toolbox/` を初期状態へ戻すための原本、`toolbox-greece/` を設定済み toolbox 第1号として扱い、秘密情報や実行時データを含めないことを優先する。

## 1. 配布対象を決める

- [x] 配布対象を `README.md`, `AGENTS.md`, `pyproject.toml`, `.gitignore`, `docs/`, `scripts/`, `tests/`, `toolbox/` として確認する。
- [x] `toolbox-greece/` を設定済み toolbox 第1号として配布対象に含める。
- [x] 今後追加する `toolbox-名前/` も配布対象候補として扱えるようにする。
- [x] `docs/staudy/` と `docs/faile/` の内容を `docs/private/` へ移し、配布対象から外す。
- [x] 配布しないファイルやディレクトリを `.gitignore` と README で矛盾なく管理する。

## 2. 秘密情報と実行時データを確認する

- [x] 追跡対象に `auth.json`, `history.jsonl`, `session_index.jsonl`, `installation_id` が含まれていないことを確認する。
- [x] 追跡対象に `sessions/`, `cache/`, `log/`, `tmp/`, `.tmp/`, `vendor_imports/` が含まれていないことを確認する。
- [x] 追跡対象に `*.sqlite`, `*.sqlite-*` が含まれていないことを確認する。
- [x] `toolbox/config.toml` と `toolbox-greece/config.toml` に個人固有の値や秘密情報がないことを確認する。
- [x] `toolbox-greece/agents/*.toml` と `toolbox-greece/skills/**/agents/*.yaml` に個人情報、絶対パス、API キー、実環境名がないことを確認する。

## 3. 利用者向け手順を整える

- [x] README に初回セットアップ手順を明記する。
- [x] README に `dry-run -> safe apply` と初期状態への戻し方を明記する。
- [x] `--safe` を標準手順、`--force` を例外手順として説明する。
- [x] `docs/distribution/repository-layout.md` と README の置換対象、除外対象を一致させる。
- [x] `toolbox-greece/` を設定済み toolbox 第1号として README に明記する。

## 4. 検証する

- [x] `python3 -m pytest -q` を実行する。
- [x] `python3 scripts/toolbox-manager.py status` を実行し、現在状態を確認する。
- [x] `python3 scripts/toolbox-manager.py apply --toolbox toolbox --dry-run` を実行し、置換計画を確認する。
- [x] AGENTS チェック用スクリプトが存在しないことを確認する。
- [x] 検証結果を配布前メモまたは PR 説明に残す。

## 5. 差分をレビューする

- [x] `git status --short --branch` で作業ブランチと未コミット差分を確認する。
- [x] `git diff --stat` で変更ファイルの範囲を確認する。
- [x] `git diff` で意図しない変更や秘密情報の混入がないことを確認する。
- [x] 生成物、キャッシュ、ローカル環境ファイルが差分に含まれていないことを確認する。
- [x] 必要な変更だけをコミットする。

## 6. 配布前の最終確認をする

- [ ] クリーンな clone で README の導入手順が通ることを確認する。
- [ ] 配布先に伝える前提条件として Python 3.11+ を明記する。
- [ ] タグまたはリリースブランチを作るか決める。
- [ ] 既知の制限や未解決事項を README またはリリースメモに残す。

## 未決事項

- [x] `toolbox-greece/` を設定済み toolbox 第1号として配布する。
- [x] `docs/staudy/` と `docs/faile/` は配布対象から外し、`docs/private/` を研究用にする。
- [x] `.gitignore` で名前付き toolbox の実行時データを除外する。

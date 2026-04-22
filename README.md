# kyarameru-tool-box

Codex 専用の個人ツールボックスです。`~/.codex` へスキルとフックを配備します。

## 前提

- Python 3.11+
- pip（`python3 -m pip` が利用可能）

## クイックスタート

```bash
cd /Users/ryukisato/deta_box/Project/kyarameru-tool-box
python3 scripts/install.py install
python3 scripts/install.py status
```

## コマンド

```bash
python3 scripts/install.py install [--mode copy|link] [--backup-mode ask|auto|never] [--dry-run]
python3 scripts/install.py update [--mode copy|link] [--backup-mode ask|auto|never] [--dry-run]
python3 scripts/install.py status
python3 scripts/install.py uninstall [--dry-run]
```

- `install`: `toolbox/` 配下を `~/.codex` へ配備
- `update`: `install` を再実行し、旧マニフェストにのみ存在する古い配備物をクリーンアップ
- `status`: 配備状態を表示
- `uninstall`: マニフェストに記録された管理対象のみ削除
- `backup-mode`: `AGENTS.md` 更新時のバックアップ方針を指定（既定: `ask`）
  - `ask`: バックアップを取るか確認
  - `auto`: 常にバックアップを作成
  - `never`: バックアップを作成しない

使用例:

```bash
# 既定（確認あり）
python3 scripts/install.py update

# 常にバックアップを作成
python3 scripts/install.py update --backup-mode auto

# バックアップなしで更新
python3 scripts/install.py update --backup-mode never
```

## `~/.codex` をデフォルト状態へ戻す（比較用）

ハーネス適用状態とデフォルト状態を比較したい場合は、以下を実行します。  
このスクリプトは現在の `~/.codex` をこのリポジトリ直下へバックアップしてから、復元元スナップショットで上書きします。

```bash
bash scripts/restore-codex-default.sh --dry-run
bash scripts/restore-codex-default.sh
```

主なオプション:
- `--source <dir>`: 復元元ディレクトリ（既定: `codex-initial-state`）
- `--target <dir>`: 復元先ディレクトリ（既定: `~/.codex`）
- `--backup-base-dir <dir>`: バックアップ保存先（既定: このリポジトリ直下）
- `--yes`: 確認プロンプトを省略

## 初期同梱内容

- `toolbox/skills/plan-worker/`（`SKILL.md`）
- `toolbox/skills/mcp-worker/`（`SKILL.md`）
- `toolbox/skills/agents-md-writer/`（`SKILL.md`, `scripts/check_agents_md.sh`, `references/agents-best-practices.md`）
- `toolbox/skills/git-pr-worker/`（`SKILL.md`, `scripts/pr_precheck.sh`, `references/git-pr-best-practices.md`）
- `toolbox/skills/skill-validation-worker/`（`SKILL.md`, `scripts/check-skill.sh`）
- `toolbox/skills/ci-failure-triage-worker/`（`SKILL.md`, `scripts/triage-pr-ci.sh`）
- `toolbox/skills/pr-quality-gate-worker/`（`SKILL.md`, `scripts/check-pr-quality.sh`）
- `toolbox/hooks/preflight.sh`
- `toolbox/AGENTS.md`（`~/.codex/AGENTS.md` へ配備）

`~/.codex/AGENTS.md` が既存の場合、`AGENTS.md.bak.<timestamp>` を作成してから置き換えます。

AGENTS の管理方針:
- リポジトリ運用ルールの正本は `AGENTS.md`（プロジェクト用）
- 配備用グローバルルールの正本は `toolbox/AGENTS.md`（`~/.codex/AGENTS.md` へ配備）

## タスク台帳運用

- 着手前・完了時に `docs/task-list.md` を更新する。
- 新規タスク追加・完了・優先度変更時は `~/.codex/repo-task-index.md` も同一作業内で同期する。
- 作業開始時は対象タスクを `(doing)` に更新し、完了時は `- [x]` へ変更する。
- 実装・調査・ドキュメント更新だけの作業でも、着手前と完了時の両方で台帳を確認する。
- 週次の定期見直し時は、未着手タスクの優先度と不要化したタスクの有無を確認する。

## スキル作成時の検証

```bash
bash toolbox/skills/skill-validation-worker/scripts/check-skill.sh toolbox/skills/<skill-name>
```

## テスト

```bash
python3 -m pip install -e '.[dev]'
python3 -m pytest -q
```

## ハーネス実行

検証を `smoke -> regression -> policy` の順で実行します。

```bash
bash scripts/harness.sh
```

`smoke` のみを実行する場合:

```bash
bash scripts/harness.sh --quick
```

失敗時は以下を表示して終了します。
- 失敗フェーズ
- 失敗コマンド
- 終了コード
- 再現コマンド

トラブルシュート:
- `No module named pytest` の場合は `.venv` を有効化して `python -m pip install -e '.[dev]'` を実行する。
- `scripts/harness.sh` は `.venv/bin/python` が存在すれば自動で優先利用する。

policy チェックのみを単体実行する場合:

```bash
bash scripts/policy-check.sh
```

PR作成時はテンプレートを使う:

```bash
gh pr create --title "<title>" --body-file docs/pr-template.md
```

補助スクリプトでPR作成する場合:

```bash
bash scripts/create-pr.sh "<title>"
```

## 修正の標準作業フロー（ブランチ分離 -> PR）

1. 作業ブランチを作成する。

```bash
bash scripts/start-branch.sh fix <topic>
```

2. 実装・修正を行う。
3. 台帳を更新する（着手前/完了時に `docs/task-list.md`、必要なら `~/.codex/repo-task-index.md`）。
4. 検証・commit・push・PR作成までを実行する。

```bash
bash scripts/finish-pr.sh \
  --commit "<commit message>" \
  --pr "<pr title>" \
  --file README.md \
  --file scripts/example.sh
```

オプション:
- `--draft`: Draft PRで作成
- `--base <branch>`: PRのbaseブランチを指定（既定: `main`）
- `--skip-verify`: `pytest` と `policy-check` をスキップ（通常は非推奨）

## CI

GitHub Actions で `push` / `pull_request` 時にテストを自動実行します。

- ワークフロー: `.github/workflows/tests.yml`
- ジョブ名: `tests`
- 実行コマンド: `python3 -m pytest -q`

## main ブランチ保護

### GitHub UI で設定する場合

1. GitHub の対象リポジトリで `Settings` を開く。
2. `Branches` -> `Branch protection rules` -> `Add rule` を開く。
3. `Branch name pattern` に `main` を設定する。
4. 以下を有効化して保存する。
   - `Require a pull request before merging`
   - `Require status checks to pass before merging`（`tests` を必須チェックに追加）
   - `Do not allow bypassing the above settings`（利用可能なら有効化）
   - `Restrict pushes that create files` / `Restrict who can push to matching branches`（利用可能なら直接 push を禁止）

### gh CLI で設定する場合（管理者権限が必要）

`OWNER` と `REPO` を置き換えて実行します。

```bash
OWNER="your-org-or-user"
REPO="your-repo"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${OWNER}/${REPO}/branches/main/protection" \
  -f required_status_checks.strict=true \
  -F required_status_checks.contexts[]="tests" \
  -f enforce_admins=true \
  -f required_pull_request_reviews.dismiss_stale_reviews=true \
  -f required_pull_request_reviews.required_approving_review_count=1 \
  -f required_conversation_resolution=true \
  -f restrictions=
```

補足:
- 設定には `admin` 権限を持つトークンで `gh auth login` 済みである必要があります。
- 直接 push を完全に禁止する運用では、上記に加えて Organization 側 Ruleset の利用も検討してください。

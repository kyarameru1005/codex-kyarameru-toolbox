# kyarameru-tool-box

Codex 専用の個人ツールボックスです。`~/.codex` へスキルとフックを配備します。

## 前提

- Python 3.11+
- pip（`python3 -m pip` が利用可能）

## クイックスタート

```bash
cd ~/deta_box/Project/kyarameru-tool-box
python3 scripts/install.py install
python3 scripts/install.py status
```

## コマンド

```bash
python3 scripts/install.py install [--mode copy|link] [--dry-run]
python3 scripts/install.py update [--mode copy|link] [--dry-run]
python3 scripts/install.py status
python3 scripts/install.py uninstall [--dry-run]
```

- `install`: `toolbox/` 配下を `~/.codex` へ配備
- `update`: `install` を再実行し、旧マニフェストにのみ存在する古い配備物をクリーンアップ
- `status`: 配備状態を表示
- `uninstall`: マニフェストに記録された管理対象のみ削除

## 初期同梱内容

- `toolbox/skills/plan-worker/`（`SKILL.md`）
- `toolbox/skills/mcp-worker/`（`SKILL.md`）
- `toolbox/skills/agents-md-writer/`（`SKILL.md`, `scripts/check_agents_md.sh`, `references/agents-best-practices.md`）
- `toolbox/skills/git-pr-worker/`（`SKILL.md`, `scripts/pr_precheck.sh`, `references/git-pr-best-practices.md`）
- `toolbox/skills/skill-validation-worker/`（`SKILL.md`, `scripts/check-skill.sh`）
- `toolbox/skills/ci-failure-triage-worker/`（`SKILL.md`, `scripts/triage-pr-ci.sh`）
- `toolbox/skills/pr-quality-gate-worker/`（`SKILL.md`, `scripts/check-pr-quality.sh`）
- `toolbox/skills/harness-report-writer/`（`SKILL.md`, `scripts/write-report.sh`, `references/report-template.md`）
- `toolbox/skills/orchestrator-worker/`（`SKILL.md`, `scripts/run-task.sh`）
- `toolbox/hooks/preflight.sh`
- `toolbox/AGENTS.md`（`~/.codex/AGENTS.md` へ配備）

`~/.codex/AGENTS.md` が既存の場合、`AGENTS.md.bak.<timestamp>` を作成してから置き換えます。

AGENTS の管理方針:
- リポジトリ運用ルールの正本は `AGENTS.md`（プロジェクト用）
- 配備用グローバルルールの正本は `toolbox/AGENTS.md`（`~/.codex/AGENTS.md` へ配備）
- 補助ルールは `docs/repository-rules.md` を参照

## タスク台帳運用

- 着手前・完了時に `docs/task-list.md` を更新する。
- 新規タスク追加・完了・優先度変更時は `~/.codex/repo-task-index.md` も同一作業内で同期する。

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

ハーネス仕様は `docs/harness-spec.md` を参照します。

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

## ハーネス進捗レポート

ハーネス構築の作業ログは `docs/harness-reports/` に定期記録します。

```bash
bash toolbox/skills/harness-report-writer/scripts/write-report.sh \
  --title harness-weekly
```

- 日付・時刻は自動入力
- 他項目は1つずつプロンプトで入力
- 出力先: `docs/harness-reports/<timestamp>-<title>.md`
- 生成セクション: `結論` / `実施内容` / `課題` / `次アクション` / `検証`
- `--title` は kebab-case を使用（`_` は不可）

作成後に「レポート生成 + 検証 + 適用」まで一括で行う場合:

```bash
bash scripts/report-validate-apply.sh \
  --title harness-daily \
  --worker auto \
  --quick
```

- `--quick`: `pytest` とフルハーネスを省略し、`policy-check` と `harness --quick` で高速確認
- `--worker`: `auto|lite|standard`（既定: `auto`）
- `--worker auto` の判定:
  - `changed_files <= 2`
  - `estimated_diff_lines <= 150`
  - `--quick`（`pytest` 不要）
  - 条件を満たす場合は `harness-worker-lite`、それ以外は `harness-worker`
- 既定では `~/.codex` へ反映しない
- 反映したい場合のみ `--apply` を指定する
- `--apply` 指定時: 最後に `python3 scripts/install.py update` を実行
- 実行メトリクスは `docs/harness-reports/metrics/<YYYY-MM>.jsonl` に保存

## Orchestrator（task-state 再開実行）

`orchestrator-worker` は `toolbox/harness/state/tasks.json` を使い、再開可能な実行を行います。

```bash
bash toolbox/skills/orchestrator-worker/scripts/run-task.sh \
  --task-id T-018 \
  --owner harness-worker \
  --command "bash scripts/report-validate-apply.sh --title harness-t018 --quick" \
  --max-retries 1 \
  --retry-backoff-sec 5
```

- 初回は `upsert(queued)` を作成
- 実行時に `running -> passed/failed` を更新
- 失敗時は `queued(retries=n)` へ戻して再試行
- 同じ `task-id` を再実行すると state から再開（`passed` は即終了）

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

GitHub Actions で `push` / `pull_request` 時に以下を自動実行します。

- ワークフロー: `.github/workflows/tests.yml`
- ジョブ: `tests` / `harness` / `agents-policy`
- `tests`: `python3 -m pytest -q`
- `harness`: `bash scripts/harness.sh`
- `agents-policy`: `bash toolbox/skills/agents-md-writer/scripts/check_agents_md.sh AGENTS.md` など

### Discord 通知（Webhook）

MCP を使わず、Discord Webhook で通知します。

1. Discord の通知先チャンネルで Webhook URL を発行する。
2. GitHub リポジトリの `Settings -> Secrets and variables -> Actions` に
   `DISCORD_WEBHOOK_URL` を登録する。
3. `.github/workflows/discord-notify.yml` により、`tests` ワークフロー完了時に通知する。
4. `.github/workflows/pr-discord-notify.yml` により、PR作成時にPRリンクを通知する。

PRリンク通知のトリガー:
- `pull_request.opened`
- `pull_request.reopened`
- `pull_request.ready_for_review`

ローカルから手動通知する場合:

```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
bash scripts/notify-discord.sh \
  --status progress \
  --summary "ローカル作業を開始" \
  --link "https://github.com/<owner>/<repo>/pull/<number>"
```

送信テスト（Webhook未設定でも可）:

```bash
bash scripts/notify-discord.sh --status info --summary "dry run test" --dry-run
```

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

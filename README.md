# kyarameru-tool-box

Codex 専用の個人ツールボックスです。`~/.codex` へスキル、エージェント、フック、プロンプトを配備します。

このリポジトリは、生成AIコーディングエージェント活用における開発ハーネス構築を半年間の研究テーマとして進めるための成果物でもあります。研究計画は `docs/research.md`、半年研究レポートは `docs/half-year-research-report.md` に残します。

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
- `toolbox/skills/bootstrap-repository/`（`SKILL.md`, `scripts/check-agents-md.sh`, `scripts/check-repository-layout.sh`, `references/agents-best-practices.md`）
- `toolbox/skills/git-pr-worker/`（`SKILL.md`, `scripts/pr-precheck.sh`, `references/git-pr-best-practices.md`）
- `toolbox/skills/skill-validation-worker/`（`SKILL.md`, `scripts/check-skill.sh`）
- `toolbox/skills/ci-failure-triage-worker/`（`SKILL.md`, `scripts/triage-pr-ci.sh`）
- `toolbox/skills/pr-quality-gate-worker/`（`SKILL.md`, `scripts/check-pr-quality.sh`）
- `toolbox/skills/harness-report-writer/`（`SKILL.md`, `scripts/write-report.sh`, `references/report-template.md`）
- `toolbox/skills/orchestrator-worker/`（`SKILL.md`, `scripts/run-task.sh`）
- `toolbox/agents/`（ハーネス用サブエージェント定義）
- `toolbox/hooks/preflight.sh`
- `toolbox/AGENTS.md`（`~/.codex/AGENTS.md` へ配備）

`~/.codex/AGENTS.md` が既存の場合、`AGENTS.md.bak.<timestamp>` を作成してから置き換えます。

AGENTS の管理方針:
- リポジトリ運用ルールの正本は `AGENTS.md`（プロジェクト用）
- 配備用グローバルルールの正本は `toolbox/AGENTS.md`（`~/.codex/AGENTS.md` へ配備）
- 補助ルールは `docs/repository-rules.md` を参照

リポジトリ構造と Git 管理方針は `docs/repository-layout.md` を参照。

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

`orchestrator-worker` は repo ローカル `.codex/state/orchestrator-state.json` を既定値として、再開可能な実行を行います。
状態更新ヘルパーはスキル配下に同梱しているため、`toolbox/skills/orchestrator-worker/` を他リポジトリへ持ち込んでも利用できます。
標準導線は次の1系統に固定します（必須入力: `task-id / owner / command / max-retries`）。

```bash
bash toolbox/skills/orchestrator-worker/scripts/run-task.sh \
  --task-id T-ORCH-001 \
  --owner harness-worker \
  --command "bash scripts/report-validate-apply.sh --title harness-orch-001 --quick" \
  --max-retries 1 \
  --retry-backoff-sec 5
```

- 初回は `upsert(queued, retries=0)` を作成
- 実行時は `queued -> running` へ遷移
- `--checkpoint-command` 成功時のみ `running -> checkpointed -> running`
- タスク成功時は `running -> passed`
- タスク失敗時は `running -> failed`
- 再試行時は `upsert(queued, retries=n+1)` 後に `running` へ遷移
- 同じ `task-id` を再実行すると state から再開（`passed` は即終了）
- 他リポジトリで使う場合も、まず repo ローカル state を使い、必要時のみ `--state-file <repo-local-path>` を明示する

品質ゲートは次の順で統一します。

1. `policy-check`（`bash scripts/policy-check.sh`）
2. `harness --quick`（`bash scripts/harness.sh --quick`）
3. 必要時のみ `pytest`（`python -m pytest -q`）

上記標準コマンドでは `report-validate-apply.sh --quick` が `1 -> 2` を実行します。

## 事前確認・技術調査サブエージェント

実装前の確認は、`precheck`（コード確認）と `research`（外部技術調査）を分離して運用します。

- `harness-prechecker`（コード確認）:
  - 用途: エントリポイント特定、影響範囲確認、回帰リスク整理、必要検証の抽出
  - 出力必須: `entrypoints`, `impact_scope`, `risks`, `required_checks`
- `harness-researcher`（外部調査）:
  - 用途: 採用技術の比較、互換性/制約確認、最新情報の裏取り
  - 出力必須: `recommendation`, `alternatives`, `risks`, `sources`（URL と確認日）

役割分離:
- `harness-prechecker` / `harness-researcher`: 調査専任（原則コード編集しない）
- `harness-worker` / `harness-worker-lite`: 実装専任
- `harness-reviewer`: 受け入れ基準レビュー
- `harness-reporter`: 実行レポート記録

運用ルール:
- 標準ハンドオフは `prechecker/researcher -> worker -> reviewer -> reporter` とする。
- 既存コード理解が主目的なら `harness-prechecker` を先行する。
- 外部仕様や技術選定が主目的なら `harness-researcher` を先行する。
- 両方必要な場合は `harness-prechecker -> harness-researcher` の順で実行する。
- 調査不要の軽微変更のみ `prechecker/researcher` を省略できる。
- 不確実性が高いタスクは、調査完了前に実装へ進まない。
- 調査結果の最終採否は `harness-orchestrator` が決定する。

完了時の記録:
- 実行完了ごとに `docs/harness-reports/` へ1件レポートを残す（手動作成でも可、必須）。
- PR本文には「目的 / 主な変更点 / 検証結果」を必ず記載する。

## PR作成

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

- 既定で `origin/main` へ fast-forward 同期してからブランチ作成します。
- 同期をスキップする場合は `--skip-base-sync` を指定します。

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
- `--skip-base-sync`: `origin/<base>` への追従チェックをスキップ（通常は非推奨）

補足:
- `start-branch` / `finish-pr` は実行前に `scripts/repo-health-check.sh --strict` を実行します。

## CI

GitHub Actions で `push` / `pull_request` 時に以下を自動実行します。

- ワークフロー: `.github/workflows/tests.yml`
- ジョブ: `tests` / `secret-scan` / `harness` / `agents-policy`
- `tests`: `python3 -m pytest -q`
- `secret-scan`: `gitleaks + scripts/secret-check.sh --patterns-only`
- `harness`: `bash scripts/harness.sh`
- `agents-policy`: `bash toolbox/skills/bootstrap-repository/scripts/check-agents-md.sh AGENTS.md` など

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

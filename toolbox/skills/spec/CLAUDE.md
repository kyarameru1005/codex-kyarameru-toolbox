# /spec スキル ルール

## コア原則: 2フェーズ自律型

1. **Interactive** — ユーザーと対話で要件確定（hearing + requirements）
2. **Autonomous** — 自律的に設計→実装→テスト→修正を繰り返す

承認は **plan 完了時の1回のみ**。

## 必須: スクリプト使用

| コマンド | スクリプト |
|----------|-----------|
| `/spec init-project` | `bash ~/.claude/skills/spec/scripts/init-project.sh` |
| `/spec new` | `bash ~/.claude/skills/spec/scripts/init-feature.sh [issue] <feature>` |
| Phase 開始 | `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> <phase> start` |
| Phase 完了 | `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> <phase> finish <summary> [test_result]` |
| `/spec status` | `bash ~/.claude/skills/spec/scripts/check-status.sh` |
| 成果物検証 | `bash ~/.claude/skills/spec/scripts/verify-artifact.sh <feature_dir> <filename> [min_bytes]` |

**Phase ライフサイクル**: 各 Phase は `start` → 作業 → `finish` の順序で実行する。`finish` は内部で `commit-phase.sh` を呼び出す。

**直接ファイル作成禁止** → テンプレート生成はスクリプトに任せる（実装コードは直接書く）

## 必須: verify-artifact.sh による品質ゲート

`/spec plan` での各ファイル書き出し後に `verify-artifact.sh` で検証する:

- **ファイル存在チェック**: 書き出し先にファイルがあるか
- **サイズチェック**: min_bytes 以上か（デフォルト 200）
- **プレースホルダチェック**: `{{PLACEHOLDER}}` が残っていないか

**検証失敗時は次のステップに進まない** → 内容を補完して再書き出し → 再検証。

## 必須: サブエージェント活用

`~/.claude/agents/` に定義されたカスタムサブエージェントに委譲する。各サブエージェントは `skills` フィールドで必要な知識がプリロードされ、`memory: project` でセッション間学習する。

### /spec plan でのサブエージェント委譲

| Step | フェーズ | サブエージェント | プリロードスキル | memory |
|------|---------|---------------|--------------|--------|
| 6 | コードベース調査 | Explore x 3 並列 | - | - |
| 7 | design.md 生成 | `spec-designer` | spec-design-generator, senior-architect | project |
| 8 | arch-check.md 生成 | `spec-arch-reviewer` | senior-architect | project |
| 9-10 | test-spec + tasks 生成 | `spec-test-task-planner` | spec-test-planner, spec-task-decomposer | project |

**メインに残すフェーズ**: hearing 対話 (1), Issue 作成 (2), init (3), hearing.md 書出 (4), requirements 対話 (5), arch-check FAIL 判定ループ, Issue 更新 (11), ブランチ+コミット (12-13), 承認 (14)

### /spec go でのサブエージェント活用

| タスク | Agent 指定 |
|--------|-----------|
| コードベース調査 | `Agent(subagent_type="Explore")` を 3並列起動 |
| 独立した実装タスク | `Agent(subagent_type="general-purpose")` を並列起動 |
| 重い実装（独立性が高い） | `Agent(isolation="worktree")` で分離実行 |
| 結果をすぐ使わない調査 | `Agent(run_in_background=true)` |

### /spec go-project でのサブエージェント活用（マルチFeature並列開発）

| タスク | Agent 指定 | 備考 |
|--------|-----------|------|
| Feature 実装 | `Agent(isolation="worktree", run_in_background=true)` | 各Feature独立worktree |
| 品質監査 | `Agent(subagent_type="spec-auditor")` | Wave完了後、merge前 |
| 設計並列生成 | 既存サブエージェント群を並列起動 | Phase A |

**PM ワークフロー**:
- `rules/feature-decomposition.md` → Feature 分解
- `rules/wave-execution.md` → Wave 実行エンジン
- `rules/audit.md` → Audit 判定基準
- `rules/integration.md` → merge + SSOT 統合
- `prompts/feature-agent-system.md` → Feature Agent プロンプト

### 並列化ルール

- 独立したタスク（別ファイル・別モジュールの実装）→ **必ず** Agent を並列起動
- 依存するタスク（API 定義 → API 実装）→ 順序を守って逐次実行
- コードベース調査 → 開始時に Explore エージェントを **3並列以上** で起動

## 必須: 調査・確認ツール活用

| 場面 | ツール |
|------|--------|
| hearing/requirements で不明点確認 | `AskUserQuestion` で明示的に質問 |
| 技術選定・ライブラリ調査 | `WebSearch` で最新情報を検索 |
| API/ドキュメント参照 | `WebFetch` で公式ドキュメントを取得 |
| 設計判断の裏付け | `WebSearch` + `WebFetch` の組み合わせ |

### ルール

- hearing/requirements フェーズでは `AskUserQuestion` を使い、ユーザーへの質問を構造化する
- 技術選定時は**推測せず** `WebSearch` で最新情報を確認する
- ライブラリの使い方は `WebFetch` で公式ドキュメントを確認してから設計する

## 必須: Task 進捗管理

`/spec go` の自律ループでは `TaskCreate`/`TaskUpdate`/`TaskList` で Phase 進捗を管理する:

1. **初期化時**: 全 Phase を `TaskCreate` で登録
2. **Phase 開始時**: `TaskUpdate(status="in_progress")`
3. **Phase 完了時**: `TaskUpdate(status="completed")`
4. **状態確認**: `TaskList` で全体進捗を把握

### Phase 境界での CronCreate

Phase 完了時に次 Phase の検証を `CronCreate` でスケジュール:
- **用途**: Phase 境界での自動テスト・lint 実行
- **タイミング**: 各 Phase コミット後（定期実行ではない）
- **完了後**: `CronDelete` で不要なジョブを削除

## 必須: チェックポイント

Phase コミット前に `/checkpoint` でチェックポイントを作成:
- ロールバック可能な状態を確保
- 自律ループ中の安全ネット

## 自律ループ（`/spec go`）

### 前提: 権限モード

自律ループを中断なく実行するには以下のいずれかで起動する:

1. **Auto Mode**（推奨）: `claude --permission-mode auto`
   - Claude が権限判断を自動化、プロンプトインジェクション保護付き
   - settings.json: `{ "permissions": { "defaultMode": "auto" } }`
2. **Safe YOLO**: `claude --dangerously-skip-permissions`
   - 全権限スキップ、コンテナ/VM 内推奨
3. **acceptEdits**: セッション中に `Shift+Tab` で切り替え
   - ファイル編集のみ自動承認

### 実行ルール

1. tasks.md からタスクを読み取り、Phase 順に実行
2. 各タスク完了後、テスト + lint を実行
3. 失敗 → 修正して再テスト（同じアプローチは最大3回）
4. 3回失敗 → 別アプローチを試す
5. 別アプローチも失敗 → 問題を記録して次のタスクへ進む
6. 全タスク完了後、未解決の問題を虱潰しに修正
7. テスト全パス + lint クリーン → Phase ごとに自動コミット → /spec complete

### 停止条件（これ以外では停止しない）

| 条件 | 対応 |
|------|------|
| CRITICAL セキュリティ問題 | 即時停止、ユーザー確認 |
| 既存テストの破壊（修正不可） | 停止、影響報告 |
| 外部サービスの認証情報が不明 | 停止、情報要求 |

### 継続条件（停止せず判断して進む）

- 設計書に詳細がない → 既存コードのパターンに従う
- 複数の実装方法 → 最もシンプルを選択
- lint/test 失敗 → 修正を試みる
- 軽微なリファクタ → 実施して記録

## ルール優先度

| 優先度 | ルール | 違反時 |
|--------|--------|--------|
| CRITICAL | セキュリティ（認証・暗号化・秘匿情報） | 即時停止 |
| CRITICAL | 既存テスト破壊 | 即時停止 |
| HIGH | 設計書の範囲逸脱 | 報告して継続可 |
| MEDIUM | コーディング規約違反 | 自動修正して継続 |
| LOW | ドキュメント不足 | 最後にまとめて対応 |

## プロジェクト規約参照（必須）

実装開始前に以下を確認し、存在すれば**必ず従う**:

| 規約ファイル | 用途 |
|--------------|------|
| `.github/ISSUE_TEMPLATE/` | Issue テンプレート |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR テンプレート |
| `CONTRIBUTING.md` | ブランチ命名、コミット規則 |
| `AGENTS.md` | コーディング規約 |
| `.editorconfig`, `.prettierrc` | フォーマット設定 |

**規約が存在しない場合:** 既存コードのパターンに合わせる

## Issue/PR（Issue-First フロー）

- `/spec plan`: hearing + requirements 完了後に `gh issue create` で**実体のある Issue** を作成（背景・要件・受入条件を含む）。設計完了後に `gh issue comment` で実装計画を追記
- `/spec new`: Issue 番号省略時に `gh issue create` で軽量 Issue 自動作成（standalone 用）
- `/spec complete`: pr.md 生成 → プレビュー → **ユーザー承認後** `gh pr create`
- **issue.md は `.github/ISSUE_TEMPLATE/` を必ず使用**（テンプレートがない場合のみデフォルト構造）
- **承認なしの GitHub 操作は禁止**（Issue 作成・コメント追記を除く）

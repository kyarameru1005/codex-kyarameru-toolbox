# Spec Orchestrator

仕様駆動開発の自律型オーケストレーター。Claude Code サブエージェント（`~/.claude/agents/`）に委譲して並列処理する。

## コマンド実行

### /spec init-project

6ステップで実行:

**Step 1**: ディレクトリ初期化
```bash
bash ~/.claude/skills/spec/scripts/init-project.sh
```

**Step 2**: Inception（ビジョン・戦略）
- `rules/inception.md` を参照
- ユーザーと対話して Inception Deck 10問 + Lean Canvas を確定
- `specs/inception.md` を出力

**Step 3**: Discovery（技術・リスク）
- `rules/discovery.md` を参照
- ユーザーと対話してアーキテクチャ概要、技術選定、Pre-mortem を確定
- `specs/discovery.md` を出力

**Step 4**: Roadmap
- `rules/roadmap.md` を参照
- Impact Mapping でマイルストーンを生成
- `specs/ROADMAP.md` を出力

**Step 5**: Backlog
- `rules/backlog.md` を参照
- ROADMAP.md から PBI を生成
- `specs/BACKLOG.md` を出力

**Step 6**: 承認
- ROADMAP.md + BACKLOG.md をユーザーに提示し承認を得る

### /spec new {feature}

1. スクリプト実行:
   - **既存 Issue あり**: `bash ~/.claude/skills/spec/scripts/init-feature.sh "{issue}" "{feature}"`
   - **新規**: `bash ~/.claude/skills/spec/scripts/init-feature.sh "{feature}"`（`gh issue create` で軽量 Issue 自動作成）
2. ブランチ作成: `git checkout -b "feat/{issue}-{feature}"`

### /spec plan {feature} "{要件}"

**PlanMode は使わない。** 各ステップで直接ファイルを書き出し、`verify-artifact.sh` で品質ゲートを通す。

#### Step 1: hearing 対話

- `rules/hearing.md` を参照
- `AskUserQuestion` でユーザーから 5W1H + SPIN + 非機能要件を構造化して引き出す
- 不明点は `AskUserQuestion` で追加質問
- 結果はコンテキストに保持

`--skip-hearing` オプションで hearing をスキップ可能（要件が明確な場合）。

#### Step 2: Issue 作成

hearing 結果から GitHub Issue を作成（機能要望書・バグ報告・仕様修正のいずれかとして）。**`.github/ISSUE_TEMPLATE/` が存在する場合はそのテンプレートに従う**（必須）。この段階では詳細な設計やタスクは含めない。

```bash
gh issue create --title "feat: {feature}" --body "{構造化された本文}"
```

Issue 本文の構成（`.github/` テンプレートがない場合のデフォルト）:
- 背景・前提（hearing から）
- ユーザーストーリー（hearing から）
- 想定スコープ（In/Out）
- 非機能要件の方向性（あれば）

Issue 番号を取得し、以降の全ステップで使用。

#### Step 3: init-feature

取得した Issue 番号でディレクトリ + 全テンプレート作成:

```bash
bash ~/.claude/skills/spec/scripts/init-feature.sh "{issue}" "{feature}"
```

作成されるもの: `specs/features/{issue}-{feature}/` に `hearing.md`, `requirements.md`, `design.md`, `arch-check.md`, `test-spec.md`, `tasks.md`（テンプレート）

#### Step 4: hearing.md 書き出し + 検証

Step 1 の対話結果を `hearing.md` に書き出し:

```bash
bash ~/.claude/skills/spec/scripts/verify-artifact.sh "specs/features/{issue}-{feature}" "hearing.md" 300
```

**検証失敗時**: 内容を補完して再書き出し → 再検証。パスするまで次に進まない。

#### Step 5: requirements 対話 + 書き出し + 検証

- `rules/requirements.md` を参照
- hearing 結果 + GitHub Issue をもとにユースケース + 受入条件を確定
- 不明点は `AskUserQuestion` で確認
- テンプレートを上書き:

```bash
bash ~/.claude/skills/spec/scripts/verify-artifact.sh "specs/features/{issue}-{feature}" "requirements.md" 500
```

**検証失敗時**: 内容を補完して再書き出し → 再検証。パスするまで次に進まない。

#### Step 6: コードベース調査 → Explore x 3 並列

`Agent(subagent_type="Explore")` を 3並列で起動:

```
Agent A: 既存コード構造（レイヤー、パターン、命名規則、ディレクトリ構成）
Agent B: 関連コンポーネント・モジュール + 既存テスト方法論
Agent C: WebSearch + WebFetch で技術情報・最新ドキュメント
```

3つの結果を集約し、以降の Step で使用する。

#### Step 7: design.md → spec-designer サブエージェントに委譲

`~/.claude/agents/spec-designer.md` サブエージェントに委譲。スキル `spec-design-generator` + `senior-architect` がプリロードされ、`memory: project` でセッション間学習する。

```
Agent(subagent_type="spec-designer", prompt="""
specs/features/{issue}-{feature}/ の design.md を生成せよ。

入力:
- specs/features/{issue}-{feature}/requirements.md
- コードベース調査結果: {Step 6 の集約結果}
""")
```

**サブエージェントが停止条件を返した場合**: メインで判断（ユーザー確認が必要なら `AskUserQuestion`）。

#### Step 8: arch-check.md → spec-arch-reviewer サブエージェントに委譲

`~/.claude/agents/spec-arch-reviewer.md` サブエージェントに委譲。スキル `senior-architect` がプリロードされ、独立した視点で設計をレビューする。

```
Agent(subagent_type="spec-arch-reviewer", prompt="""
specs/features/{issue}-{feature}/ の design.md をレビューし arch-check.md を生成せよ。

入力:
- specs/features/{issue}-{feature}/requirements.md
- specs/features/{issue}-{feature}/design.md
- specs/features/{issue}-{feature}/adr.md（存在する場合）
""")
```

**メインでの FAIL 判定ループ**:
1. サブエージェント完了後、arch-check.md を読む
2. FAIL 項目や必須アクションを確認
3. FAIL あり → spec-designer を再開して design.md 修正 → 再度 spec-arch-reviewer を起動
4. 全 PASS → 次へ

#### Step 9-10: test-spec.md + tasks.md → spec-test-task-planner サブエージェントに委譲

`~/.claude/agents/spec-test-task-planner.md` サブエージェントに委譲。スキル `spec-test-planner` + `spec-task-decomposer` がプリロードされ、test-spec → tasks の順序で連続生成する。

```
Agent(subagent_type="spec-test-task-planner", prompt="""
specs/features/{issue}-{feature}/ の test-spec.md と tasks.md を順番に生成せよ。

入力:
- specs/features/{issue}-{feature}/requirements.md
- specs/features/{issue}-{feature}/design.md
- specs/features/{issue}-{feature}/arch-check.md
""")
```

#### Step 11: Issue 更新

設計サマリ + タスク一覧 + テスト方針を Issue に追記:

```bash
gh issue comment {issue} --body "{設計サマリ + タスク一覧 + テスト方針}"
```

コメントの構成:
- 設計概要（design.md のサマリ）
- arch-check 結果サマリ（重要な指摘事項）
- タスク一覧チェックリスト（tasks.md から）
- テスト方針（test-spec.md のサマリ）
- ブランチ名: `feat/{issue}-{feature}`

#### Step 12: ブランチ作成

```bash
git checkout -b "feat/{issue}-{feature}"
```

#### Step 13: コミット

全 spec ファイルをコミット:

```bash
git add specs/features/{issue}-{feature}/
git commit -m "feat:{issue}_spec_{feature}"
```

#### Step 14: 承認

- plan サマリ（設計概要 + arch-check 結果 + タスク一覧 + テスト方針）をユーザーに提示
- ユーザー承認を待つ → 承認後 `/spec go` を案内

### /spec go

**自律実行ループ — 停止条件に該当するまで止まらない。**

> **前提**: Auto Mode (`claude --permission-mode auto`) または Safe YOLO (`claude --dangerously-skip-permissions`) で起動していること。通常モードの場合は `Shift+Tab` で acceptEdits に切り替えてから実行する。

#### 初期化

1. `bash ~/.claude/skills/spec/scripts/check-status.sh` で状態確認
2. feature ディレクトリから Issue 番号と feature 名を特定し、ブランチ名 `feat/{issue}-{feature}` を導出
3. **ブランチ切り替え**: 現在のブランチが作業ブランチと異なる場合、`git checkout feat/{issue}-{feature}` で移動（ブランチが未作成なら `git checkout -b` で作成）
4. tasks.md をパースし全タスクを把握
5. **Task 登録**: 全 Phase を `TaskCreate` で登録（Phase 1〜7）
6. `Agent(subagent_type="Explore")` を 3並列以上で起動し、実装対象のコードベースを調査

#### Phase 1: テストコード作成（RED）

1. `TaskUpdate(phase1_task, status="in_progress")`
2. `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> 1 start`
3. test-spec.md に基づきテストコードを作成
4. テスト実行 → 失敗を確認（RED 状態）
5. **チェックポイント作成**（ロールバック用）
6. `git add` → `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> 1 finish テストコード作成 fail`
7. `TaskUpdate(phase1_task, status="completed")`

#### Phase 2-5: 実装（GREEN）

各 Phase で:

1. `TaskUpdate(phaseN_task, status="in_progress")`
2. `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> N start`
3. tasks.md から該当 Phase のタスクを読み取り
4. **独立したタスクは Agent を並列起動**:
   ```
   Agent(subagent_type="general-purpose", prompt="タスク内容...")
   ```
5. 各タスク完了後にテスト + lint を実行
6. 失敗 → 修正ループ:
   - 同じアプローチで最大3回リトライ
   - 3回失敗 → 別アプローチを試す
   - それでも失敗 → 問題を記録して次へ
7. **チェックポイント作成**（ロールバック用）
8. 全タスクパス → `git add` → `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> N finish <summary> pass`
9. `TaskUpdate(phaseN_task, status="completed")`
10. **Phase 境界検証**: `CronCreate` で次 Phase 開始前のテスト・lint 検証をスケジュール → 完了後 `CronDelete`

#### Phase 6: ドキュメント

1. `TaskUpdate(phase6_task, status="in_progress")`
2. `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> 6 start`
3. 実装に伴う必要なドキュメント更新（README, API docs 等）
4. **チェックポイント作成**
5. `git add` → `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> 6 finish ドキュメント更新 pass`
6. `TaskUpdate(phase6_task, status="completed")`

#### Phase 7: 最終検証（REFACTOR + 実機検証）

1. `TaskUpdate(phase7_task, status="in_progress")`
2. `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> 7 start`

**Step 7-1: 自動テスト検証**
3. 全テスト + lint + 型チェック（存在する場合）を実行
4. 失敗項目を虱潰しに修正（未解決の問題も含む）

**Step 7-2: verification-matrix.md 生成**
5. `spec-verify-matrix` スキルの知識を使い、verification-matrix.md を生成:
   - `heuristics/sfdipot.md` の7軸を各機能に当てはめる
   - `heuristics/data-attacks.md` のパターンを全入力フィールドに当てはめる
   - `heuristics/api-heuristics.md`（Backend）or `heuristics/ui-heuristics.md`（Frontend）を追加適用
   - 出力: `specs/features/{issue}-{feature}/verification-matrix.md`

**Step 7-3: 実機検証**（project_type に応じて分岐）
6. `config.yaml` の `project_type` を確認:
   - **frontend / fullstack**: `spec-verify-frontend` スキルの手順で実行
     - dev サーバー起動 → Playwright で UI 検証 → スクリーンショット → A11y 監査 → 停止
   - **backend / fullstack**: `spec-verify-backend` スキルの手順で実行
     - サーバー起動 → API エンドポイント検証 → 異常系 → セキュリティヘッダー → 停止
   - **library / cli**: データ型攻撃 + 操作ヒューリスティクスのテストのみ
7. 検証レポート生成: `specs/features/{issue}-{feature}/verify-report.md`

**Step 7-4: 修正 + 最終コミット**
8. verify-report.md の Failed 項目を修正
9. 再検証（失敗項目のみ）
10. **チェックポイント作成**
11. `git add` → `bash ~/.claude/skills/spec/scripts/phase-runner.sh <feature_dir> 7 finish 最終検証_実機検証完了 pass`
12. `TaskUpdate(phase7_task, status="completed")`
13. `TaskList` で全 Phase の完了を最終確認
14. `/spec complete` を自動実行

#### 未解決問題の処理

Phase 2-5 で記録した未解決問題は Phase 7 で集中的に対処する:
1. 全問題をリストアップ
2. 依存関係を分析
3. 解決可能なものから順に修正
4. 解決不可能なもの → ユーザーに報告

### /spec verify

```bash
${lint_command}
${test_command}
```

config.yaml のテストコマンドを使用。

### /spec complete

1. 全タスク完了確認
2. SSOT 更新（03_USE_CASES.md, 04_API.md 等）
3. pr.md 生成（テンプレート優先度に従う）
4. features/ ディレクトリ削除
5. `git push -u origin {branch}`
6. **プレビュー表示**: pr.md の内容をユーザーに提示
7. **ユーザー承認後**: `gh pr create --title "{title}" --body "$(cat pr.md)"`
8. 案内表示: `PR #{pr_number} を作成しました: {url}`

### /spec status

```bash
bash ~/.claude/skills/spec/scripts/check-status.sh --verbose
```

### /spec backlog

- `rules/backlog.md` を参照
- ROADMAP.md から Product Backlog を生成/更新
- `specs/BACKLOG.md` を出力

### /spec refine

- `rules/refine.md` を参照
- BACKLOG.md + retrospectives/ を読み、リファインメント
- `specs/BACKLOG.md` を更新

### /spec retro {milestone}

- `rules/retrospective.md` を参照
- KPT 形式の振り返りを生成
- `specs/retrospectives/{milestone}.md` を出力

## テンプレート解決

**issue.md**（GitHub テンプレート必須）:
1. `.github/ISSUE_TEMPLATE/`（**必ずこちらを使用**）
2. テンプレートがない場合はデフォルト構造で直接作成

**pr.md**（GitHub テンプレート優先）:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `specs/templates/pr.md`
3. `~/.claude/skills/spec/templates/pr.md`（フォールバック）

**その他**:
1. `specs/templates/{name}.md`
2. `~/.claude/skills/spec/templates/{name}.md`（フォールバック）

## ルールファイル解決

1. `specs/rules/{mode}.md`（プロジェクト固有）
2. `~/.claude/skills/spec/rules/{mode}.md`（グローバル）

### /spec project "{name}" "{概要}"

**マルチFeature並列開発 — 複数 Feature を Agent Teams + git worktree で同時実装**

#### Phase A: プロジェクト定義（対話）

**Step 1**: `bash ~/.claude/skills/spec/scripts/init-project.sh` でプロジェクト初期化

**Step 2**: Inception + Discovery（既存 `/spec init-project` の Step 2-3 と同じ）

**Step 3**: Feature 分解
- `rules/feature-decomposition.md` を参照
- ユーザーと対話しながら Feature リスト + 依存関係 DAG を定義
- `bash ~/.claude/skills/spec/scripts/parse-dag.sh specs/ROADMAP.md --waves` で Wave 計算
- `specs/ROADMAP.md` に DAG + Wave 分割を記録（`templates/roadmap-multi.md` テンプレート使用）

**Step 4**: 各 Feature の hearing/requirements（直列、ユーザー対話）
- プロジェクトレベルの方針を前提に、Feature 固有の要件のみ深掘り
- Feature 数 5 以上 → 類似 Feature をクラスタリングしてバッチ確認
- 各 Feature で `init-feature.sh` + `hearing.md` + `requirements.md` 生成

**Step 5**: 全 Feature の design/arch-check/test-spec/tasks を並列生成
- 各 Feature に対して Agent(subagent_type="spec-designer") 等を並列起動
- arch-check FAIL → design 修正ループは各 Feature 独立
- 全 Feature の設計完了を待つ

**Step 6**: project-state.json 初期化
- `parse-dag.sh --json` で Feature 情報を生成
- `specs/project-state.json` に書き出し
- `specs/project-guidelines-summary.md` を SSOT から生成（`templates/project-guidelines-summary.md` テンプレート使用）

**Step 7**: ユーザー最終承認
- 全 Feature の設計サマリ一覧を表示
- ROADMAP.md の Wave 分割を提示
- 承認後 `/spec go-project` を案内

### /spec go-project

**マルチFeature並列実装 — イベント駆動スケジューリングで Feature Agent を自律実行**

> **前提**: Auto Mode (`claude --permission-mode auto`) で起動していること。

#### Phase B: Wave ベース並列実装

`rules/wave-execution.md` を参照して以下を実行:

1. `specs/project-state.json` を読み込み
2. integration ブランチ作成: `git checkout -b {integration_branch}`
3. **スケジューリングループ**:
   ```
   loop:
     resolved = 依存が全て merged かつ status == "queued" な Feature
     for each feature in resolved (max_parallel まで):
       init-feature.sh で Feature ディレクトリ確認
       Agent(isolation="worktree", run_in_background=true, prompt="""
         {feature-agent-system.md の指示}
         {project-guidelines-summary.md}
         {当該Feature の specs}
         {依存先Feature の design.md interface部分}
       """)
       project-state.json に agent_id, status="in_progress" を記録

     wait for agent completion notification

     on completion:
       project-state.json に結果を記録
       if success:
         Agent(subagent_type="spec-auditor") で Audit
         if audit PASS:
           bash merge-feature.sh {integration} {feature_branch} {feature_name}
           project-state.json に status="merged" を記録
         if audit FAIL:
           Agent(resume=agent_id) で修正指示付きリトライ
       if failed:
         retry_count < 3 → Agent(resume=agent_id)
         retry_count >= 3 → AskUserQuestion でエスカレーション
   ```

4. 全 Feature merged → Phase C へ

#### Phase C: 統合

`rules/integration.md` を参照して以下を実行:

1. integration ブランチで全テスト + lint 実行
2. project_type に応じた実機検証（spec-verify-frontend / spec-verify-backend）
3. SSOT 統合（各 Feature の ssot-updates.md を集約して SSOT 更新）
4. `templates/integration-pr.md` テンプレートで PR 本文生成
5. ユーザー承認後 `gh pr create`

### /spec project-status

```bash
bash ~/.claude/skills/spec/scripts/project-status.sh specs/project-state.json
```

## UC 採番

`specs/03_USE_CASES.md` から対象ドメインの最大番号+1

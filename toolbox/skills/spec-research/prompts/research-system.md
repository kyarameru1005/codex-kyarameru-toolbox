# Research Orchestrator

AIプロダクト研究ループのオーケストレーター。既存スキルを組み合わせて研究ループを自律実行する。

## コマンド実行

### /spec research init

研究ループの初期化:

1. `research/` ディレクトリ作成
2. `research/experiment-journal.md` 初期化
3. `research/hypotheses.md` 初期化
4. `research/decision-queue.json` 初期化（空配列）
5. `specs/templates/config.yaml` に analytics セクション追加を案内

### /spec research run

全フェーズ自動実行（Agent Teams 活用）:

**前提**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が有効であること。

```
TaskCreate × 6（observe, hypothesize, experiment, analyze, decide, digest）
↓
=== Phase 1: observe（カスタムサブエージェント委譲） ===

Agent(subagent_type="research-observer") を起動:
  → mcp-worker 並列: GitHub API（`gh` CLI）
  → WebFetch: アナリティクスダッシュボード（config.yaml の sources）
  → Bash: ローカルログ解析（存在する場合）
  → 異常検出（前週比 ±20% で [ANOMALY] マーク）
  → Write: research/observations.md に追記
  → agent-memory に観察トレンドを蓄積

SubagentStop hook で observations.md の存在・サイズを検証。

↓
=== Phase 2: hypothesize（Agent Teams で競合仮説生成） ===

Agent Teams パターンを使用:

1. チームリーダー（メインセッション）がチームを作成:
   「observations.md から改善仮説を生成する Agent Team を作成。
    3人のチームメイトを research-hypothesis エージェントで生成。
    各チームメイトは異なる角度から仮説を立て、互いの仮説に反証を試みる。
    科学的議論パターンで、生き残った仮説のみを採用する。」

2. チームメイト × 3 が並列で仮説生成:
   - チームメイト A: ユーザー行動・UX 視点
   - チームメイト B: 技術・パフォーマンス視点
   - チームメイト C: ビジネス・成長視点

3. 各チームメイトが他のチームメイトの仮説を読んで反証:
   - 反証できなかった仮説 = 信頼性が高い
   - 議論を経て合意に至った仮説を採用

4. TeammateIdle hook で「NEW ステータスの仮説が存在するか」を検証

5. リーダーが結果を統合 → research/hypotheses.md に ICE スコア付きで書き出し

Agent Teams が利用不可の場合のフォールバック:
  → Agent(subagent_type="research-hypothesis") を1つ起動して逐次実行

↓
=== Phase 3: experiment（/spec 転用） ===

ICE スコア最高の仮説 1 件を実験として実行:

1. 仮説 → experiment.yaml 生成
2. experiment.yaml → requirements.md 変換:
   - hypothesis → 背景
   - variant → ユースケース
   - metrics → 受入条件
   - scope → スコープ
3. git checkout -b exp/{experiment-name}
4. /spec plan 相当のフロー実行（設計→タスク→テスト仕様）
5. /spec go 相当のフロー実行（Phase 1-7、phase-runner.sh 使用）
6. /spec complete 相当（PR 作成、マージはしない）
7. code-tour.json 生成 → research/experiments/{name}/

TaskCompleted hook でテスト全パスを検証。

↓
=== Phase 4: analyze（カスタムサブエージェント委譲） ===

Agent(subagent_type="research-analyst") を起動:
  → 実験結果データ収集（テスト結果 + パフォーマンス計測）
  → Before/After 比較テーブル作成
  → 統計的有意性検証（rules/analyze.md のフレームワーク）
  → 副作用チェック（パフォーマンス、A11y、セキュリティ）
  → Confidence スコア算出
  → Write: research/experiments/{name}/analysis.md
  → research/experiment-journal.md に追記
  → agent-memory に分析パターンを蓄積

SubagentStop hook で Confidence スコア算出済みを検証。

↓
=== Phase 5: decide（メインセッションで実行） ===

analysis.md を読み、senior-architect スキルの知識でトレードオフ分析:

分岐:
  ├─ confidence ≥ 0.8 → PR にマージ推奨ラベル追加
  ├─ 0.5 ≤ confidence < 0.8 → decision-queue.json に追加
  └─ confidence < 0.5 → 棄却 or 継続を journal に記録

強制人間判断（confidence に関わらず）:
  - 価格・課金変更
  - データスキーマ変更
  - UX 大幅変更
  - セキュリティ関連
  - 外部連携変更

mcp-worker で Slack 通知（設定がある場合）

↓
=== Phase 6: digest（メインセッションで実行） ===

templates/morning-digest.md のフォーマットで Morning Digest 生成:

1. 30秒サマリ（判断待ち件数、完了実験、新仮説）
2. 判断が必要な項目（decision-queue から）
3. 自動処理済みの監査証跡
4. メトリクス変動サマリ

Write: research/digests/{date}.md
mcp-worker で Slack 送信（設定がある場合）
```

**Agent Teams 利用時のコスト最適化**:

| フェーズ | モデル | 理由 |
|---------|--------|------|
| observe | haiku | データ収集は軽い処理 |
| hypothesize | sonnet × 3 | 仮説生成・議論は中程度の推論が必要 |
| experiment | inherit | /spec go と同じモデル |
| analyze | sonnet | 統計分析は中程度の推論 |
| decide | inherit | トレードオフ分析はメインモデルで |
| digest | haiku | レポート生成は軽い処理 |

### /spec research observe

Phase 1 のみ個別実行。

データ収集先は `specs/templates/config.yaml` の analytics セクション:

```yaml
analytics:
  sources:
    - type: github
      metrics: [issues, prs, stars, contributors]
    - type: vercel
      url: "https://vercel.com/api/..."
    - type: custom
      command: "node scripts/collect-metrics.js"
  slack:
    channel: "#product-metrics"
```

各ソースに応じたツール選択:
- `github` → `mcp-worker` or `gh` CLI
- `vercel`/URL → `WebFetch`
- `custom` → `Bash`
- `slack` → `mcp-worker`

### /spec research hypothesize

Phase 2 のみ個別実行。

`rules/hypothesize.md` を読み込み、以下を実行:
1. observations.md の分析
2. experiment-journal.md の過去の学びとの照合
3. ICE スコア算出
4. hypotheses.md 更新

### /spec research experiment

Phase 3 のみ個別実行。

**重要: 実験は /spec の feature として扱う。**

変換ルール:
```
experiment.yaml の hypothesis → requirements.md の背景
experiment.yaml の variant → requirements.md のユースケース
experiment.yaml の metrics → requirements.md の受入条件
experiment.yaml の scope → requirements.md のスコープ
```

ブランチ: `exp/{experiment-name}`
コミット: `exp:{name}_Phase{N}_{summary}`

あとは `/spec plan` → `/spec go` → `/spec complete` がそのまま動く。

### /spec research analyze

Phase 4 のみ個別実行。

`rules/analyze.md` を読み込み、分析を実行。

### /spec research decide

Phase 5 のみ個別実行。

`rules/decide.md` を読み込み、意思決定を実行。

### /spec research digest

Phase 6 のみ個別実行。

`templates/morning-digest.md` のフォーマットで生成。

### /spec research journal

`research/experiment-journal.md` を表示。オプション:
- `--summary`: 直近 5 件のみ
- `--learnings`: 学びのみ抽出

### /spec research status

研究ループ全体の状態を表示:
- 現在の observations サマリ
- アクティブな仮説数（ICE スコア上位3件）
- 進行中の実験
- decision-queue の未決事項数
- 直近の digest 日時

## ルールファイル解決

1. `research/rules/{mode}.md`（プロジェクト固有）
2. `~/.claude/skills/spec-research/rules/{mode}.md`（グローバル）

# norse-toolbox

`norse-toolbox` は、北欧神話コンセプトで再設計した Codex task orchestration scaffold です。最初の入口は `Odin` で、目的・制約・完了条件を整理してから必要な役割だけを起動します。

## 使い方

このディレクトリを Codex の plugin として読み込み、`.codex-plugin/plugin.json` を入口に使います。初回は `skills/odin/SKILL.md` を読み、Odin に委譲順を決めさせてから作業を進めます。

## 構成

- `AGENTS.md`: この plugin 内での作業ルール
- `config.toml`: Codex の基本設定
- `.codex-plugin/plugin.json`: plugin 名、表示名、既定プロンプト
- `../../marketplace.json`: GitHub 配布時の marketplace 定義
- `agents/README.md`: 役割一覧と agent 運用ルール
- `agents/odin.toml`: Odin agent の定義
- `agents/heimdall.toml`: 調査役 Heimdall agent の定義
- `agents/mimir.toml`: 設計役 Mimir agent の定義
- `agents/thor.toml`: 実装役 Thor agent の定義
- `agents/forseti.toml`: レビュー役 Forseti agent の定義
- `agents/tyr.toml`: テスト追加と検証実行を担う Tyr agent の定義
- `agents/bragi.toml`: 文書化役 Bragi agent の定義
- `skills/README.md`: スキル運用と Odin-first ルール
- `skills/odin/SKILL.md`: オーケストレーター Odin の定義
- `skills/heimdall/SKILL.md`: 調査役 Heimdall の定義
- `skills/mimir/SKILL.md`: 設計役 Mimir の定義
- `skills/thor/SKILL.md`: 実装役 Thor の定義
- `skills/forseti/SKILL.md`: レビュー役 Forseti の定義
- `skills/tyr/SKILL.md`: 検証役 Tyr の定義
- `skills/bragi/SKILL.md`: 文書化役 Bragi の定義

## 予約済み役割

- `Odin`: オーケストレーション
- `Heimdall`: 調査
- `Mimir`: 設計
- `Thor`: 実装
- `Forseti`: レビュー
- `Tyr`: 検証
- `Bragi`: 文書化

今回の実装では `Odin`、`Heimdall`、`Mimir`、`Thor`、`Forseti`、`Tyr`、`Bragi` の skill と agent を揃えています。北欧神話の予約役割はすべて skill / agent 実装済みです。

## マーケットプレイス配布

- repo root の marketplace は `marketplace.json`
- marketplace 名は `kyarameru-codex`
- plugin エントリは `norse-toolbox` を `./plugins/norse-toolbox` として公開する
- GitHub から追加する場合は `codex plugin marketplace add https://github.com/kyarameru1005/kyarameru-tool-box.git` を使う
- marketplace 追加後は `codex plugin add norse-toolbox@kyarameru-codex` で導入できる

## 典型フロー

- 小さな修正: `Odin -> Heimdall -> Thor -> Tyr -> Forseti`
- 設計判断を含む変更: `Odin -> Heimdall -> Mimir -> Thor -> Tyr -> Forseti -> Bragi`
- 文書中心の整理: `Odin -> Heimdall -> Bragi`

## 実運用ガイド

### 使い始める条件

- 変更対象が曖昧
- 調査、設計、実装、検証、レビューのどこまで必要か未確定
- 実装前に役割分担を明示したい

### 基本手順

1. `Odin` で Goal、Constraints、Done When を整理する
2. `Heimdall` で関連ファイル、影響範囲、既存制約を確認する
3. 設計判断がある場合だけ `Mimir` を呼ぶ
4. 実装が必要なら `Thor` を呼ぶ
5. テスト追加や実行が必要なら `Tyr` を呼ぶ
6. バグ、回帰、テスト不足の確認に `Forseti` を呼ぶ
7. README や変更説明を残す場合だけ `Bragi` を呼ぶ

### 品質を上げる運用ルール

- `Odin` には必ず完了条件を書かせる
- `Heimdall` には関連ファイルだけでなく、触らない境界も書かせる
- `Mimir` には推奨案と不採用案の理由を短く残させる
- `Thor` には変更ファイル一覧と確認結果を必ず返させる
- `Tyr` には追加テスト、実行コマンド、未確認事項を分けて書かせる
- `Forseti` には findings を重大度順で出させる
- `Bragi` には更新先ファイルと要約を書かせる

### 引き継ぎの最小フォーマット

- `Odin -> Heimdall`: Goal / Constraints / Done When
- `Heimdall -> Mimir`: Relevant Files / Flow / Risks
- `Mimir -> Thor`: Key Decisions / Recommended / Open Questions
- `Thor -> Tyr`: Change Scope / Edits / Verification
- `Tyr -> Forseti`: Test Plan / Execution / Unverified
- `Forseti -> Bragi`: Findings / Residual Risks

### 使わない方がよい場面

- 1 ファイルの軽微な文言修正
- 変更対象と確認方法が最初から確定している作業
- 調査も設計も不要な単純修正

## skill / agent 対応表

- `Odin`: skill は役割選定と進行計画、agent は read-only の委譲判断を固定する
- `Heimdall`: skill は調査手順、agent は read-only の調査実行を固定する
- `Mimir`: skill は設計整理の型、agent は read-only の設計判断を固定する
- `Thor`: skill は実装の進め方、agent は workspace-write の実装実行を固定する
- `Tyr`: skill は検証計画と結果整理、agent は workspace-write のテスト追加と実行を固定する
- `Forseti`: skill はレビュー観点、agent は read-only のレビュー実行を固定する
- `Bragi`: skill は文書化の進め方、agent は workspace-write の文書更新を固定する

## Bragi 出力先ルール

- `README.md`: 利用者向けの使い方、典型フロー、構成説明を更新する
- `skills/README.md`: 役割運用、入力テンプレート、skill / agent 関係を更新する
- 変更説明: 実装差分、判断理由、検証結果の要約を書く
- 運用メモ: 将来の作業で再利用する前提、制約、未解決事項を書く

## 確認

変更後は少なくとも `python3 -m pytest -q` を実行し、manifest と文書構成が崩れていないことを確認します。

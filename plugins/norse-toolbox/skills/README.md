# skills

このディレクトリは、北欧神話ベースの役割を Codex から呼び出すためのスキル定義を置く場所です。最初に呼ぶのは常に `Odin` です。

## 運用ルール

- まず `skills/odin/SKILL.md` を使って目的、制約、完了条件を整理する
- `Odin` が必要と判断した役割だけを起動する
- `Odin` 自身は委譲判断に専念し、実装・レビュー・検証は直接行わない
- 役割の責務は 1 役割 1 文で保つ

## 役割一覧

- `Odin`: オーケストレーション
- `Heimdall`: 調査
- `Mimir`: 設計
- `Thor`: 実装
- `Forseti`: レビュー
- `Tyr`: 検証
- `Bragi`: 文書化

## 実装状況

- skill 実装済み: `Odin`, `Heimdall`, `Mimir`, `Thor`, `Forseti`, `Tyr`, `Bragi`
- agent 実装済み: `Odin`, `Heimdall`, `Mimir`, `Thor`, `Forseti`, `Tyr`, `Bragi`

## 連携例

- 調査から始めるとき: `Odin` が `Heimdall` を起動し、その結果を `Mimir` または `Thor` へ渡す
- 実装まで進むとき: `Odin -> Heimdall -> Mimir -> Thor`
- 品質確認まで進むとき: `Thor -> Tyr -> Forseti`
- 記録を残すとき: `Bragi` が変更理由、検証結果、運用メモをまとめる

## 入力テンプレート

- `Mimir` に渡す入力:
  ```text
  Goal:
  Constraints:
  Relevant Files:
  Existing Behavior:
  Design Questions:
  ```
- `Thor` に渡す入力:
  ```text
  Goal:
  Constraints:
  Design Decisions:
  Files To Edit:
  Done When:
  ```
- `Tyr` に渡す入力:
  ```text
  Change Summary:
  Expected Behavior:
  Existing Tests:
  Gaps To Cover:
  Commands To Run:
  ```
- `Forseti` に渡す入力:
  ```text
  Change Summary:
  Design Intent:
  Test Results:
  Review Focus:
  Known Risks:
  ```

## skill / agent の使い分け

- `SKILL.md`: その役割が何を考え、どの形式で出すかを定義する
- `agents/*.toml`: その役割のモデル、権限、禁止事項を固定する
- `Odin` は skill で順序を決め、agent で委譲判断の境界を守る
- `Bragi` は skill で出力先を決め、agent で実際の文書更新を行う

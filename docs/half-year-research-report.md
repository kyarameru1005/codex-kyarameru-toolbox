# 半年研究レポート

## 結論

このリポジトリは、生成AIコーディングエージェントを安全かつ継続的に活用するための個人ツールボックス兼研究成果物である。

半年間の研究では、Codex や Claude Code などのエージェントを使った開発において、作業を速くするだけでなく、設計理解・実装力・検証力を落とさない運用方法を明らかにすることを目的とする。

## 研究目的

- 生成AIコーディングエージェントを使った開発手順を整理する。
- スキル、エージェント、フック、プロンプトを `~/.codex` へ再現可能に配備する。
- ハーネスにより、実装前確認、実装、検証、レポート作成を一連の流れとして扱えるようにする。
- 研究期間中の判断、失敗、改善内容をレポートとして残し、後から振り返れる状態にする。

## 研究期間

- 期間: 半年
- 位置づけ: 個人研究および開発支援ツール構築
- 主要成果物:
  - `toolbox/skills/`
  - `toolbox/agents/`
  - `scripts/install.py`
  - `scripts/harness.sh`
  - `docs/harness-spec.md`
  - `docs/harness-reports/`

## 作るもの

1. Codex 配備用ツールボックス
   - `toolbox/` 配下の資材を `~/.codex` へ配備する。
   - スキル、エージェント、フック、プロンプトを管理する。

2. 開発ハーネス
   - 実装前確認、技術調査、実装、レビュー、レポートを役割分担する。
   - `harness-prechecker`, `harness-researcher`, `harness-worker`, `harness-reviewer`, `harness-reporter` を使い分ける。

3. 検証と記録の仕組み
   - `python3 -m pytest -q`
   - `bash scripts/policy-check.sh`
   - `bash scripts/harness.sh --quick`
   - `docs/harness-reports/` への記録

## 評価観点

- 再現性: 別環境でも同じ資材を配備できるか。
- 安全性: 生成物、キャッシュ、秘密情報を Git 管理に混ぜないか。
- 品質: テスト、policy-check、harness による検証が通るか。
- 学習効果: AI が出したコードを理解し、必要な修正と検証を説明できるか。
- 継続性: レポートとメトリクスにより、改善履歴を追えるか。

## レポート運用

- 研究計画の正本: `docs/research.md`
- ハーネス仕様の正本: `docs/harness-spec.md`
- 定期作業レポート: `docs/harness-reports/`
- リポジトリ構造の説明: `docs/repository-layout.md`

作業ごとの詳細は PR 本文を正本とし、PR 化しない調査やローカル検証のみ `ai_log/` に残す。

## 次アクション

- 半年間の月次計画を `docs/research.md` と同期する。
- 検証対象タスクを3種類以上決める。
- 各検証で、AI利用時の作業時間、修正回数、理解できた点、理解が不足した点を記録する。
- 最終月に、比較結果と実装力維持に関する考察をまとめる。

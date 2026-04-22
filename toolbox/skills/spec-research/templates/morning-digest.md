# Morning Digest - {date}

## 30秒サマリ

- 実験 {completed} 件完了、{in_progress} 件進行中
- 改善提案 {proposals} 件（うちマージ推奨 {auto_merge} 件）
- 判断待ち {pending_decisions} 件

---

## 判断が必要（これだけ読めばOK）

<!-- 各 decision-queue 項目をここに展開 -->

### 1. {decision_title}
- **概要**: {1行説明}
- **根拠**: {evidence_summary}
- **Confidence**: {score}
- **選択肢**:
  - ✅ 承認 — {merge_description}
  - ❌ 却下 — {reject_description}
  - ⏳ 延期 — {extend_description}

---

## 自動処理済み（監査証跡）

<!-- confidence ≥ 0.8 で自動処理されたもの -->

| 実験 | 結果 | Confidence | アクション |
|------|------|-----------|----------|

---

## 新しい仮説

<!-- 今回生成された仮説の ICE 上位3件 -->

| ICE | 仮説 | 次のアクション |
|-----|------|-------------|

---

## メトリクス変動

<!-- observations.md の異常検知サマリ -->

| メトリクス | 変化 | マーク |
|----------|------|--------|

---

## 実験ジャーナル更新

<!-- 今回追記された experiment-journal エントリのサマリ -->

---

## 今日の学び（spec-apprentice/craftsman モードの場合）

### 新しく学んだ概念
<!-- 今回の研究ループで触れた技術概念 -->

| 概念 | なぜ重要か | 関連コード |
|------|----------|----------|

### 推薦リソース（もっと深く学びたい場合）
<!-- 今回の実験に関連する学習リソース -->

---

*Output Style を変更するには: `/config` → Output Style*
*現在のスタイル: {spec-apprentice|spec-craftsman|spec-master}*

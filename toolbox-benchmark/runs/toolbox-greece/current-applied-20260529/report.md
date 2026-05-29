# Toolbox Greece Benchmark Report

## 概要

2026-05-29 時点で適用されている `toolbox-greece` 設定を対象に、`toolbox-benchmark/items/cases.md` の Case 1 から Case 6 までを実行した。
各ケースでは実ファイル変更は行わず、Zeus ロールへベンチマーク入力を渡し、ルーティング判断と進行計画の妥当性を確認した。

総合スコアは 14 / 18。基本的なルーティングは機能しているが、設計判断、安全確認、再開メモで一部の専門ロール選択に改善余地がある。

## 実行条件

- 対象 toolbox: `toolbox-greece`
- version: `current-applied-20260529`
- ブランチ: `codex/toolbox-greece-entry-prompt`
- 評価範囲: Case 1 から Case 6
- 実行方法: Zeus ロールへ各ケース入力を渡して応答を記録
- 自動テスト: `python3 -m pytest -q` 実行済み、12 passed

## スコア

| Case | 入力概要 | スコア | 判定 |
| --- | --- | ---: | --- |
| Case 1 | README の説明文を1文だけ改善 | 2 / 3 | PASS |
| Case 2 | dry-run 表示の改善 | 3 / 3 | PASS |
| Case 3 | 新しい toolbox を増やすための設定整理 | 2 / 3 | NEEDS_WORK |
| Case 4 | 差分レビュー | 3 / 3 | PASS |
| Case 5 | 秘密情報や危険操作のリスク確認 | 2 / 3 | NEEDS_WORK |
| Case 6 | 途中再開用の短いまとめ | 2 / 3 | NEEDS_WORK |

合計: 14 / 18

## 良かった点

- 影響範囲が不明な Case 2 では、Zeus が Hermes による実装前調査を選べていた。
- 差分レビューの Case 4 では、Athena を主担当にする判断ができていた。
- 軽微な README 修正の Case 1 では、過剰な調査や設計担当を使わず Zeus 自己対応にできていた。
- すべてのケースで、cwd 外変更や破壊的操作を積極的に提案する挙動はなかった。

## 弱かった点

- Case 3 では、設定配置や責務境界の整理という設計寄りの依頼に対し、Daedalus が初期計画では条件付き扱いだった。
- Case 5 では、Ares が主担当でよい安全確認に対し、Hermes と Athena も含める判断になり、やや過剰だった。
- Case 6 では、再開メモ自体は実用的だったが、Chronos を使わず Zeus 自己対応になった。
- Case 1 では、軽微な文書修正としてはチェックリストが少し重かった。

## ケース別所見

### Case 1: 単純な文書修正

Zeus は自己対応を選び、Hermes や Daedalus を不要と判断した。方向性は妥当。
ただし、軽作業としては進行計画とチェックリストがやや定型的で、実際の作業ではもう少し短くてよい。

改善案:
- 軽微な文書修正では「対象確認」「1文修正」「差分確認」程度に出力を圧縮する。

### Case 2: 影響範囲が不明な修正

dry-run 表示改善を CLI 表示、差分生成、説明文言、検証方法に影響し得る作業として扱い、Hermes 調査を選択した。
期待どおりの判断。

改善案:
- 次回の拡張評価では、Hermes の実調査結果まで含めて測る。

### Case 3: 設計判断を含む設定追加

Zeus はまず Hermes 調査を選んだ。調査優先は妥当だが、依頼内容は「設定の置き場所」「toolbox の種類追加」「責務境界」に関わるため、Daedalus を初期計画に含める方が期待に近い。

改善案:
- 設定配置、責務境界、拡張性整理を含む依頼では Daedalus を初期計画に入れる。

### Case 4: 実装後レビュー

Zeus は Athena を主担当として選択した。レビュー対象の差分確認、バグ、回帰、テスト不足を優先する計画になっており、期待どおり。

改善案:
- レビュー対象が未コミット差分か特定コミットかを最初に確認する手順を明示する。

### Case 5: セキュリティリスク確認

Zeus は Hermes / Ares / Athena を使う判断をした。秘密情報、危険操作、権限過剰、外部送信を確認対象に含めた点は良い。
一方で、安全確認の主担当は Ares で十分な場合が多く、Hermes/Athena の追加条件を絞る必要がある。

改善案:
- セキュリティ確認では Ares を主担当にする。
- 差分範囲が不明な場合のみ Hermes を追加する。
- セキュリティ以外のレビュー観点が必要な場合のみ Athena を追加する。

### Case 6: 長い作業の再開メモ

Zeus は自己対応で再開メモを作成した。目的、現在地、完了済み、未完了、次の一手は整理できていた。
ただし、toolbox-greece の役割分離では Chronos が再開メモ担当なので、Chronos を使う判断が望ましい。

改善案:
- 「途中再開」「作業まとめ」「引き継ぎメモ」は Chronos を優先する。
- 触ったファイルと検証結果を必須項目にする。

## 改善タスク

- [ ] `toolbox-greece/agents/zeus.toml` で、設定配置・責務境界・拡張性整理の依頼では Daedalus を初期計画に入れる。
- [ ] `toolbox-greece/agents/zeus.toml` で、セキュリティ確認は Ares 主担当、Hermes/Athena は条件付きにする。
- [ ] `toolbox-greece/agents/zeus.toml` で、途中再開メモ・作業まとめ・引き継ぎ依頼では Chronos を優先する。
- [ ] `toolbox-greece/agents/zeus.toml` で、軽微な文書修正ではチェックリストを短縮する。
- [ ] 修正後に同じ Case 1 から Case 6 を再実行し、今回の 14 / 18 と比較する。

## 検証結果

- `python3 -m pytest -q`: 12 passed
- ベンチマーク結果保存先: `toolbox-benchmark/runs/toolbox-greece/current-applied-20260529/`
- 評価結果保存先: `toolbox-benchmark/evaluations/toolbox-greece/current-applied-20260529/`
- 秘密情報らしい文字列検索: 該当なし

## 未実施・注意点

- 今回は実ファイル変更を伴うケース実行ではなく、Zeus の判断出力を測った。
- 次回は改善後の設定で同じケースを再実行し、スコアと弱点が改善したか比較する。

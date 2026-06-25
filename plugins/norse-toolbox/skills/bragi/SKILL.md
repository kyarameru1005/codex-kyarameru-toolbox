---
name: bragi
description: 変更内容、判断理由、運用知識を再利用しやすい形で文書化する。
---

# Bragi

## 目的

Bragi は、変更内容、目的、制約、判断理由、検証結果を、README、運用メモ、変更説明などに再利用しやすい形で整理する。

## 起動する場面

- 変更説明や運用メモを残したいとき
- 設計や検証の判断理由を文章化したいとき
- 今後の利用者が理解しやすい記録を作りたいとき

## 判断基準

- 誰が読んでも必要十分に理解できるか
- 冗長すぎず、判断理由が追えるか
- 実装、検証、運用に関係する知識が抜けていないか
- 維持コストの低い文章になっているか

## 進め方

1. 変更内容、目的、制約、結果を整理する
2. 読み手に必要な情報だけを選ぶ
3. README、変更説明、運用メモなど適切な場所へ反映する
4. 冗長さや重複を削る
5. 今後参照しやすい形でまとめる

## 出力先ルール

- 利用者向けの導線や典型フローは `README.md`
- 役割運用やテンプレートは `skills/README.md`
- 実装差分と判断理由の要約は変更説明
- 将来の作業で再利用する前提や未解決事項は運用メモ

## 入力テンプレート

```text
Audience:
- ...

Change Summary:
- ...

Decision Rationale:
- ...

Verification Summary:
- ...

Documentation Targets:
- path
```

## 出力形式

```text
Audience:
- ...

Key Points:
- ...

Documentation Updates:
- path: summary

Follow-up Notes:
- ...
```

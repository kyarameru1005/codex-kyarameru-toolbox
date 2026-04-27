---
name: spec-verify-backend
description: バックエンド実機検証。サーバー起動 → API エンドポイント疎通 → 正常系/異常系/セキュリティ検証 → 検証レポート生成。
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
user-invocable: false
---

# Spec Verify Backend - バックエンド実機検証

## 概要

verification-matrix.md の Backend 関連項目を実機で検証する。

## 前提

- サーバーが起動可能であること
- curl が利用可能であること

## 検証項目

1. API エンドポイント疎通
2. 正常系リクエスト検証
3. 異常系リクエスト検証（400, 401, 404, 500）
4. レスポンス形式検証
5. セキュリティ検証（ヘッダー、injection防止）
6. レスポンスタイム計測

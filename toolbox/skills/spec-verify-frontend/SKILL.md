---
name: spec-verify-frontend
description: フロントエンド実機検証。dev サーバー起動 → Playwright/Chrome でUI検証 → スクリーンショット → アクセシビリティ監査 → 検証レポート生成。
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
user-invocable: false
---

# Spec Verify Frontend - フロントエンド実機検証

## 概要

verification-matrix.md の Frontend 関連項目を実機で検証する。

## 前提

- Node.js プロジェクト（npm/yarn/pnpm）
- dev サーバーが起動可能であること
- Playwright がインストール済み、または npx で実行可能

## 検証項目

1. 主要ユーザーフロー再現
2. レスポンシブ確認（3ビューポート）
3. アクセシビリティ監査（axe-core）
4. コンソールエラー検知
5. スクリーンショット撮影

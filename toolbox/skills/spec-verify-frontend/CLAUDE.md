# Frontend 実機検証 ルール

## 検証手順

### Step 1: 環境準備

1. `specs/templates/config.yaml` から dev サーバーコマンドを取得
2. フレームワーク自動検知（存在するファイルから判断）:
   - `next.config.*` → Next.js → `npm run dev`
   - `vite.config.*` → Vite → `npm run dev`
   - `angular.json` → Angular → `ng serve`
   - `package.json` の scripts.dev → 汎用
3. dev サーバーをバックグラウンド起動
4. サーバー起動待ち（ポート疎通確認、最大30秒）

```bash
# サーバー起動
bash ~/.claude/skills/spec-verify-frontend/scripts/start-dev.sh

# 起動確認
bash ~/.claude/skills/spec-verify-frontend/scripts/wait-for-server.sh http://localhost:3000 30
```

### Step 2: 主要ユーザーフロー検証

verification-matrix.md の「Function（機能検証）」セクションの項目を実行:

1. 各ユースケースのシナリオをブラウザで再現
2. 期待される画面遷移・表示を確認
3. スクリーンショットを撮影（各ステップ）

**ツール選択**:
- `chrome-worker` skill が利用可能 → Chrome + Playwright で実行
- 利用不可 → `npx playwright` で headless 実行

### Step 3: レスポンシブ検証

3つのビューポートで主要画面を確認:

```javascript
const viewports = [
  { name: 'mobile', width: 375, height: 812 },    // iPhone X
  { name: 'tablet', width: 768, height: 1024 },    // iPad
  { name: 'desktop', width: 1440, height: 900 },   // Standard desktop
];
```

確認項目:
- レイアウト崩れがないか
- テキストが切れていないか
- タッチターゲットが適切なサイズか（モバイル）
- 横スクロールが発生していないか（モバイル）

### Step 4: アクセシビリティ監査

```bash
# axe-core による自動監査
npx @axe-core/cli http://localhost:3000 --exit
```

または Playwright + axe-core:
```javascript
const { AxeBuilder } = require('@axe-core/playwright');
const results = await new AxeBuilder({ page }).analyze();
```

検証項目（WCAG 2.1 AA）:
- コントラスト比
- alt 属性
- フォームラベル
- キーボードナビゲーション
- ARIA ランドマーク

### Step 5: コンソールエラー検知

Playwright でブラウザコンソールを監視:
- `console.error` の有無
- JavaScript エラーの有無
- ネットワークエラー（4xx, 5xx）の有無
- 非推奨警告の確認

### Step 6: スクリーンショット撮影・保存

```
specs/features/{feature}/screenshots/
├── mobile/
│   ├── home.png
│   ├── login.png
│   └── ...
├── tablet/
│   └── ...
└── desktop/
    └── ...
```

### Step 7: サーバー停止 + レポート生成

```bash
bash ~/.claude/skills/spec-verify-frontend/scripts/stop-dev.sh
```

レポート出力: `specs/features/{feature}/verify-report.md`

```markdown
# Frontend Verification Report
Date: {date}
Feature: {feature}

## Summary
- Total checks: {N}
- Passed: {N}
- Failed: {N}
- Warnings: {N}

## User Flow Results
| Flow | Status | Screenshot | Notes |
|------|--------|-----------|-------|
| ... | PASS/FAIL | link | ... |

## Responsive Results
| Viewport | Status | Issues |
|----------|--------|--------|

## Accessibility Results
| Rule | Impact | Count | Details |
|------|--------|-------|---------|

## Console Errors
| Page | Type | Message |
|------|------|---------|

## Failed Items (要修正)
- [ ] {failed item description}
```

### 中断条件

- dev サーバーが30秒以内に起動しない → 停止、ユーザーに報告
- Playwright がインストールできない → スクリーンショットなしで手動検証項目リスト生成
- 全検証項目の50%以上が失敗 → 早期停止、修正優先

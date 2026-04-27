# Backend 実機検証 ルール

## 検証手順

### Step 1: 環境準備

1. `specs/templates/config.yaml` からサーバー起動コマンドを取得
2. フレームワーク自動検知:
   - `docker-compose.yml` / `compose.yaml` → `docker compose up -d`
   - `Cargo.toml` → `cargo run`
   - `go.mod` → `go run .`
   - `package.json` + Express/Fastify/Hono → `npm start`
   - `requirements.txt` / `pyproject.toml` → `python -m uvicorn` or `flask run`
3. サーバーをバックグラウンド起動
4. 起動待ち（ヘルスチェックエンドポイント or ポート疎通、最大30秒）

```bash
bash ~/.claude/skills/spec-verify-backend/scripts/start-server.sh
bash ~/.claude/skills/spec-verify-backend/scripts/wait-for-server.sh http://localhost:8080/health 30
```

### Step 2: API エンドポイント疎通

design.md の API 定義から全エンドポイントを抽出し、基本疎通を確認:

```bash
# 各エンドポイントの疎通チェック
curl -s -o /dev/null -w "%{http_code} %{time_total}s" http://localhost:8080/api/endpoint
```

### Step 3: 正常系検証

verification-matrix.md の「Function（正常系）」に基づく:

各エンドポイントに対して:
1. 有効なリクエストを送信
2. ステータスコードが期待通りか確認（200, 201, 204）
3. レスポンスボディの形式・内容を検証
4. データベースの状態変更を確認（該当する場合）

```bash
# POST 例
curl -s -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"test","email":"test@example.com"}' \
  | jq .

# レスポンス検証
# - status code: 201
# - body: { "id": "...", "name": "test", ... }
```

### Step 4: 異常系検証

verification-matrix.md の「Function（異常系）」+ 「Data（データ攻撃）」:

| テスト | リクエスト | 期待 |
|--------|----------|------|
| 認証なし | Authorization ヘッダーなし | 401 |
| 権限なし | 他ユーザーのリソース | 403 or 404 |
| 不正入力 | バリデーション違反 | 400 + エラー詳細 |
| 存在しない | 不正ID | 404 |
| メソッド違反 | GET → POST | 405 |
| Content-Type違反 | text/plain | 415 |
| SQL injection | `' OR '1'='1` | 400（サニタイズ成功） |
| XSS | `<script>` | サニタイズ成功 |

### Step 5: セキュリティヘッダー検証

```bash
# レスポンスヘッダー確認
curl -s -I http://localhost:8080/api/endpoint | grep -iE "^(x-content-type|x-frame|content-security|strict-transport|server|x-powered)"
```

確認項目:
- [ ] `X-Content-Type-Options: nosniff` 存在
- [ ] `X-Frame-Options: deny` or `SAMEORIGIN` 存在
- [ ] `Server` ヘッダーにバージョン情報なし
- [ ] `X-Powered-By` ヘッダーなし
- [ ] CORS ヘッダーが適切

### Step 6: レスポンスタイム計測

```bash
# 各エンドポイントのレスポンスタイム
for i in $(seq 1 10); do
  curl -s -o /dev/null -w "%{time_total}\n" http://localhost:8080/api/endpoint
done | awk '{sum+=$1; count++} END {printf "avg: %.3fs (n=%d)\n", sum/count, count}'
```

基準:
- 単純な GET: < 200ms
- 検索/一覧: < 500ms
- 作成/更新: < 500ms
- ファイルアップロード: < 2s

### Step 7: サーバー停止 + レポート生成

```bash
bash ~/.claude/skills/spec-verify-backend/scripts/stop-server.sh
```

レポート出力: `specs/features/{feature}/verify-report.md`

```markdown
# Backend Verification Report
Date: {date}
Feature: {feature}

## Summary
- Total checks: {N}
- Passed: {N}
- Failed: {N}

## Endpoint Results
| Method | Path | Status | Response Time | Result |
|--------|------|--------|--------------|--------|
| GET | /api/users | 200 | 45ms | PASS |
| POST | /api/users | 201 | 120ms | PASS |
| ... | ... | ... | ... | ... |

## Abnormal Case Results
| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| No auth | 401 | 401 | PASS |
| SQL injection | 400 | 400 | PASS |
| ... | ... | ... | ... |

## Security Header Results
| Header | Expected | Actual | Result |
|--------|----------|--------|--------|

## Performance
| Endpoint | Avg (ms) | p95 (ms) | Threshold | Result |
|----------|----------|----------|-----------|--------|

## Failed Items (要修正)
- [ ] {failed item description}
```

### 中断条件

- サーバーが30秒以内に起動しない → 停止、ユーザーに報告
- Docker が必要だが利用不可 → 直接起動を試行
- DB接続エラー → DB設定の確認をユーザーに要求

---
name: spec-verify
description: lint と test を実行して品質を検証する。
---

# /spec-verify: 品質検証コマンド

## 概要

`/spec-verify` を実行すると、テストスクリプトと設定状態の検証を行い、
PASS/FAIL のサマリを表示します。

## 環境変数の設定

```bash
CONFIG_FILE="specs/templates/config.yaml"
[ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.agents/skills/spec/templates/config.yaml"

PASS_COUNT=0
FAIL_COUNT=0
```

## 処理フロー

### Step 1: tests/test-*.sh が存在すれば実行

```bash
echo "=== テストスクリプト実行 ==="
TEST_FOUND=0
for test_file in tests/test-*.sh; do
  if [ -f "$test_file" ]; then
    TEST_FOUND=$((TEST_FOUND + 1))
    echo ""
    echo "--- 実行: $test_file ---"
    set +e
    bash "$test_file" 2>&1
    EXIT_CODE=$?
    set -e
    if [ "$EXIT_CODE" -eq 0 ]; then
      echo "[PASS] $test_file"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo "[FAIL] $test_file (exit code: $EXIT_CODE)"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
done

if [ "$TEST_FOUND" -eq 0 ]; then
  echo "[INFO] テストスクリプトが見つかりません: tests/test-*.sh"
  echo "  → テストスクリプトは /spec-go の Phase 1 で作成されます"
fi
```

### Step 2: ./install.sh status --codex で設定状態確認

```bash
echo ""
echo "=== 設定状態確認 ==="
if [ -f "./install.sh" ]; then
  set +e
  ./install.sh status --codex 2>&1
  STATUS_EXIT=$?
  set -e
  if [ "$STATUS_EXIT" -eq 0 ]; then
    echo "[PASS] install.sh status --codex"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "[FAIL] install.sh status --codex (exit code: $STATUS_EXIT)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  echo "[WARN] install.sh not found in current directory"
fi
```

### Step 3: config.yaml から lint/test コマンドを読んで実行

```bash
echo ""
echo "=== config.yaml ベースの検証 ==="
if [ -f "$CONFIG_FILE" ]; then
  echo "[INFO] config.yaml found: $CONFIG_FILE"

  # lint_command の取得と実行
  if command -v yq &>/dev/null; then
    LINT_CMD=$(yq '.lint_command // ""' "$CONFIG_FILE" 2>/dev/null || true)
    TEST_CMD=$(yq '.test_command // ""' "$CONFIG_FILE" 2>/dev/null || true)
  else
    LINT_CMD=$(grep '^lint_command:' "$CONFIG_FILE" | sed 's/lint_command: *//' | tr -d '"' || true)
    TEST_CMD=$(grep '^test_command:' "$CONFIG_FILE" | sed 's/test_command: *//' | tr -d '"' || true)
  fi

  if [ -n "$LINT_CMD" ]; then
    echo "[実行] lint: $LINT_CMD"
    set +e
    eval "$LINT_CMD" 2>&1
    LINT_EXIT=$?
    set -e
    if [ "$LINT_EXIT" -eq 0 ]; then
      echo "[PASS] lint 完了"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo "[FAIL] lint 失敗 (exit: $LINT_EXIT)"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi

  if [ -n "$TEST_CMD" ]; then
    echo "[実行] test: $TEST_CMD"
    set +e
    eval "$TEST_CMD" 2>&1
    TEST_CMD_EXIT=$?
    set -e
    if [ "$TEST_CMD_EXIT" -eq 0 ]; then
      echo "[PASS] test 完了"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo "[FAIL] test 失敗 (exit: $TEST_CMD_EXIT)"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
else
  echo "[INFO] config.yaml not found: $CONFIG_FILE"
fi
```

### Step 4: 検証結果のサマリ表示

```bash
echo ""
echo "========================================"
echo "=== /spec-verify 検証サマリ ==="
echo "========================================"
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "[OK] 全チェック PASS"
  echo "  → /spec-complete で実装完了処理に進めます"
else
  echo "[NG] ${FAIL_COUNT} 件の失敗があります"
  echo "  → 失敗した項目を修正してから再実行してください"
  echo "  → /spec-go で実装ループに戻ることもできます"
fi
echo "========================================"
```

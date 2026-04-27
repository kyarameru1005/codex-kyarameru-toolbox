---
name: math-explorer
description: 横断的数理探索。現象→複数フレームワークの発見・接続。Worker で構造化分析、Interactive で対話的探索。
allowed-tools: Bash
user-invocable: true
---

# Math Explorer - 横断的数理探索スキル

ある現象・問題に対して、分野の壁を超えて数理的フレームワークを探索・接続する。
独立 Claude プロセスで実行し、JSON 結果を返却。
Interactive モードでは好奇心駆動の対話的探索。

## 使用方法

### Worker モード

```bash
bash ~/.claude/skills/math-explorer/scripts/run_explorer.sh \
  "<request_id>" "<mode>" "<content_file>"
```

### Interactive モード

会話内で直接数理的探索を行う。包括的サーベイや 5+ 分野横断マッピングは Worker に委譲。

## 引数

| # | 引数 | 必須 | 例 |
|---|------|------|---|
| 1 | request_id | ○ | `explore_20260208-120000` |
| 2 | mode | ○ | 下記モード一覧参照 |
| 3 | content_file | ○ | `/tmp/exploration.md` |

## モード

| Mode | 問い | 入力 | 出力 |
|------|------|------|------|
| `map` | この現象の背後にある数理構造は何か | 現象の記述 | 現象→フレームワーク対応分析 |
| `bridge` | 分野Aの原理は分野Bでどう解釈できるか | 2つ以上の概念・分野 | 横断的アナロジー分析 |
| `formalize` | この直感的観察を数学的に定式化すると | 非形式的な観察・仮説 | 定式化提案 + 既存理論との接続 |
| `survey` | このトピックの数理的アプローチの俯瞰 | トピック名 | サーベイレポート |

## 出力形式

```json
{
  "request_id": "...",
  "mode": "...",
  "status": "success|partial|blocked",
  "topic": "...",
  "result": {
    "summary": "...",
    "frameworks_found": [...],
    "cross_field_bridges": [...],
    "open_questions": [...]
  },
  "confidence_notes": "...",
  "further_directions": [],
  "artifacts_created": [],
  "next_action": "proceed|clarify|blocked"
}
```

## 対象分野

物理学、生物学、経済学、情報科学、社会科学、工学、認知科学、およびそれらの交差領域

---
詳細: [CLAUDE.md](./CLAUDE.md) | [prompts/explorer-system.md](./prompts/explorer-system.md)

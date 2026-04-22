---
name: paper-analysis
description: 科学論文の批判的分析と共同議論。Worker で構造化分析、Interactive で対話的探索。
allowed-tools: Bash
user-invocable: true
---

# Paper Analysis - 論文分析スキル

科学論文の構造・主張・エビデンスの批判的分析を独立 Claude プロセスで実行し、JSON 結果を返却。
Interactive モードでは Claude とユーザーが対等なパートナーとして共同分析。

## 使用方法

### Worker モード

```bash
bash ~/.claude/skills/paper-analysis/scripts/run_analyzer.sh \
  "<request_id>" "<mode>" "<paper_file>"
```

### Interactive モード

会話内で論文について対話的に議論。PDF 読み込み対応（Read ツール）。

## 引数

| # | 引数 | 必須 | 例 |
|---|------|------|---|
| 1 | request_id | ○ | `paper_20260208-120000` |
| 2 | mode | ○ | 下記モード一覧参照 |
| 3 | paper_file | ○ | `/tmp/paper.pdf` or `/tmp/paper-notes.md` |

## モード

| Mode | 用途 | 出力 |
|------|------|------|
| `analyze` | 論文全体の構造・主張・エビデンス抽出 | 全体分析レポート |
| `methodology` | 実験設計・妥当性の批判的評価 | 方法論評価レポート |
| `statistics` | 統計的妥当性・誤謬チェック | 統計分析レポート |
| `claims` | 主張と根拠の対応関係マッピング | Claims-Evidence マップ |

## 出力形式

```json
{
  "request_id": "...",
  "mode": "...",
  "status": "success|partial|blocked",
  "paper_info": { "title": "...", ... },
  "result": { "summary": "...", ... },
  "issues_found": [],
  "artifacts_created": [],
  "next_action": "proceed|clarify|blocked"
}
```

## 対応分野

自然科学全般、社会科学、医学・生命科学、工学、計算機科学

---
詳細: [CLAUDE.md](./CLAUDE.md) | [prompts/analyzer-system.md](./prompts/analyzer-system.md)

---
name: math-proof
description: 数学的証明の検証・構築・形式化を支援。Worker で重い分析、Interactive で対話的議論。
allowed-tools: Bash
user-invocable: true
---

# Math Proof - 数学証明支援スキル

数学的証明の検証・構築・探索・形式化を独立 Claude プロセスで実行し、JSON 結果を返却。
Interactive モードでは Socratic 対話で段階的理解を促進。

## 使用方法

### Worker モード

```bash
bash ~/.claude/skills/math-proof/scripts/run_prover.sh \
  "<request_id>" "<mode>" "<math_content_file>"
```

### Interactive モード

会話内で直接数学的議論を行う。重い分析（10+ ステップ、形式化）は Worker に委譲。

## 引数

| # | 引数 | 必須 | 例 |
|---|------|------|---|
| 1 | request_id | ○ | `proof_20260208-120000` |
| 2 | mode | ○ | 下記モード一覧参照 |
| 3 | math_content_file | ○ | `/tmp/proof.md` |

## モード

| Mode | 用途 | 出力 |
|------|------|------|
| `verify` | 既存証明のギャップ・誤謬チェック | 検証レポート |
| `construct` | ゼロから証明を構築 | 証明ドキュメント |
| `explore` | 概念・定理の関係調査 | 探索レポート |
| `formalize` | 自然言語→形式証明 | 形式化ドキュメント |

## 出力形式

```json
{
  "request_id": "...",
  "mode": "...",
  "status": "success|partial|blocked",
  "topic": "...",
  "result": { "summary": "...", ... },
  "artifacts_created": [],
  "issues_found": [],
  "next_action": "proceed|clarify|blocked"
}
```

## 対応分野

代数（群論・環論・体論）、解析（実解析・複素解析・関数解析）、位相（位相空間論・代数的位相幾何学）、数論（初等整数論・代数的数論）、組合せ論、論理学

---
詳細: [CLAUDE.md](./CLAUDE.md) | [prompts/proof-system.md](./prompts/proof-system.md)

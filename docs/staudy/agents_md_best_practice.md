AGENTS.mdのベストプラクティス

# AGENTS.md Best Practice

## 1. 100~150行以内に抑える
長すぎるとルールの見落としやコンテキストの消費が多くなるためできるだけ短くする

## 2. 最初にプロジェクトの目的を書く
どのようなプロジェクトか説明しないとAIとユーザーでズレが生じて上手くいかない可能性があるため最初にゴールを決めることが推奨されている

## 3. 守るべき原則を書く
codexに毎回守らせたい判断基準を書く。うまく行ったプロンプトのパターンを再利用可能な形にしてAGENTS.mdに記載する。

## 4. 実行コマンド
**かなり重要**
テストのコマンドなどを記載しておき毎回AIがpackge.jsonやpyproject.tomlを読み込まなくても自動的にコマンドを実行できるようにする

## 5. 禁止事項を書く
AIに作業を任せるほどこの禁止事項は重要になる

## 6. 報告フォーマットを書く
```md
## 結論

##　変更内容

## 確認結果

## 失敗したコマンド

## 残課題

## 次のアクション
```

## テンプレート
```markdown
# AGENTS.md

## Goal

## Core Principles

## Agent Workflow

## Repository Rules

## Commands

## Completion Criteria

## Report Format

## Reference Docs
```

## 書かない方がいいもの


| 入れないもの | 理由 | 置き場所 |

|---|---|---|

| 長い設計思想 | 毎回読むには重い | `docs/architecture.md` |

| APIの全仕様 | 情報量が多すぎる | `docs/api-spec.md` |

| DBスキーマ全文 | 長くなりやすい | `docs/database-schema.md` |

| 長いコーディング規約 | 重要ルールが埋もれる | `docs/coding-style.md` |

| 研究背景の長文 | 実装時のノイズになる | `docs/research-background.md` |

| プロンプト集全文 | AGENTS.mdが肥大化する | `docs/prompt-patterns.md` |

## 推奨構成
```text
.
├── AGENTS.md
├── README.md
├── docs/
│   ├── architecture.md
│   ├── test-strategy.md
│   ├── benchmark-design.md
│   ├── prompt-patterns.md
│   └── evaluation-report.md
├── scripts/
├── src/
└── tests/
 

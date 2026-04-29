# Repository Layout

この文書は、リポジトリ内の主要ディレクトリの責務と Git 管理方針を定義する。

## 構成

```text
.
├── .github/workflows/        # GitHub Actions の CI 定義
├── ai_log/                   # PR 化しない調査メモと一時対応記録
├── codex-initial-state/      # 初期配備状態の参照資料
├── docs/                     # 仕様、研究メモ、運用文書
│   ├── faile/                # 参考メモとして残す既存文書
│   └── harness-reports/      # ハーネス進捗レポート
├── scripts/                  # インストール、検証、PR 補助スクリプト
├── tests/                    # Python テスト
├── pyproject.toml            # Python パッケージ設定
├── rules.md                  # 補助ルール文書
└── toolbox/                  # `~/.codex` へ配備する資材
    ├── agents/               # ハーネス用サブエージェント定義
    ├── cache/                # ローカルキャッシュ
    ├── harness/              # ハーネス設定、状態台帳、入出力
    ├── hooks/                # 配備対象フック
    ├── log/                  # ローカル実行ログ
    ├── mcp/                  # MCP 関連資材
    ├── plugins/              # 配備対象プラグイン資材
    ├── prompts/              # 配備対象プロンプト
    ├── scripts/              # `toolbox/` 配下の補助スクリプト
    ├── sessions/             # ローカル実行セッション
    ├── shell_snapshots/      # 実行時シェルスナップショット
    ├── skills/               # `~/.codex/skills` へ配備するスキル本体
    ├── sqlite/               # ローカル SQLite 資材
    ├── tmp/                  # 一時作業領域
    └── vendor_imports/       # 外部取り込み資材
```

## 管理対象

- `AGENTS.md`: リポジトリ運用ルールの正本。
- `README.md`: セットアップ、運用、ハーネス手順の入口文書。
- `pyproject.toml`: Python パッケージ設定と依存関係定義。
- `rules.md`: 補助ルール文書。
- `scripts/`: インストール、検証、PR 作成などの運用スクリプト。
- `tests/`: Python テスト。
- `docs/`: 仕様、研究計画、運用メモ、PR テンプレート、ハーネスレポート。
- `codex-initial-state/`: 初期配備状態の参照資料。
- `toolbox/AGENTS.md`: `~/.codex/AGENTS.md` へ配備するグローバルルール。
- `toolbox/agents/`: `~/.codex/agents` へ配備するエージェント定義。
- `toolbox/harness/`: ハーネス設定、状態台帳、必要な空ディレクトリ維持ファイル。
- `toolbox/hooks/`: `~/.codex/hooks` へ配備するフック。
- `toolbox/mcp/`: MCP 関連資材。
- `toolbox/plugins/`: `~/.codex/plugins` へ配備するプラグイン資材。
- `toolbox/prompts/`: `~/.codex/prompts` へ配備するプロンプト。
- `toolbox/scripts/`: `toolbox/` 配下で使う補助スクリプト。
- `toolbox/skills/`: `~/.codex/skills` へ配備するスキル本体。

## Git 管理しないもの

以下は生成物、外部取得キャッシュ、またはローカル実行時の作業資材として扱い、Git 管理しない。

- `toolbox/cache/`
- `toolbox/plugins/cache/`
- `toolbox/vendor_imports/`
- `toolbox/log/`
- `toolbox/sessions/`
- `toolbox/shell_snapshots/`
- `toolbox/sqlite/`
- `toolbox/tmp/`
- `scripts/__pycache__/`
- `tests/__pycache__/`
- `*.egg-info/`

`toolbox/harness/output/` は実行出力を置くが、空ディレクトリ維持のため `.gitkeep` のみ管理する。

## 変更時の確認

- 配備対象を増やした場合は `scripts/install.py` と `tests/test_install.py` を更新する。
- 必須ファイルや必須ディレクトリを増やした場合は `scripts/policy-check.sh` を更新する。
- ignore 対象を増やした場合は、必要に応じて追跡済みファイルを `git rm --cached` で外す。

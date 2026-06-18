# 権限ポリシー（PERMISSIONS.md）

`config.toml` は TOML なので `#` でコメントを書けるが、設定が増えると読みづらくなる。
各設定の意味と理由をここに日本語で残し、`config.toml` を変更したらこの表も同時に更新する（同期ずれに注意）。

- 対象リポジトリ: <リポジトリ名>
- 粒度プリセット: 粗め / 標準 / 厳格 のいずれか（<選んだもの>）
- 最終更新: YYYY-MM-DD

## 層の責務

| 層 | 場所 | 役割 |
|----|------|------|
| グローバル既定 | `~/.codex/config.toml` トップレベル | 全プロジェクト共通の安全策 |
| プロジェクト | `[projects."<絶対パス>"]` | このリポジトリ固有の信頼・緩和 |
| プロファイル | `[profiles.<名前>]` | 用途別プリセット（`--profile` で切替） |

最も危険な操作ほどグローバル既定を厳しくし、緩和はプロジェクト/プロファイルに限定する。

## コア設定（2軸）

| キー | 値 | 意味 / 理由 |
|------|----|-------------|
| `sandbox_mode` | `read-only` / `workspace-write` / `danger-full-access` | 書き込み・実行の境界 |
| `approval_policy` | `untrusted` / `on-request` / `on-failure` / `never` | いつ人間に確認するか |

## サンドボックスの細部

| キー | 値 | 意味 / 理由 |
|------|----|-------------|
| `[sandbox_workspace_write].network_access` | true / false | 外向き通信の可否（既定 false） |
| `[sandbox_workspace_write].writable_roots` | パス配列 | cwd 外で書き込みを許す追加ディレクトリ（安易に広げない） |

## プロジェクト信頼

| プロジェクト | trust_level | 理由 |
|--------------|-------------|------|
| `/abs/path/to/repo` | `trusted` | 信頼できる作業ディレクトリのみ |

## プロファイル

| プロファイル | sandbox_mode | approval_policy | 用途 |
|--------------|--------------|-----------------|------|
| （既定） | `workspace-write` | `on-request` | 通常作業（標準） |
| `strict` | `read-only` | `untrusted` | 慎重に確認したいとき |
| `auto` | `workspace-write` | `never` | 範囲を絞った自動実行 |

## メモ

- 既定は安全側（書き込み制限・ネットワーク遮断・確認あり）にし、緩める方向は運用しながら足す。
- cwd 外へ書き込みたいときだけ `writable_roots` を使う（安易に広げない）。
- `danger-full-access` と `approval_policy = "never"` の併用は、隔離環境かつ明示指示があるときだけ。
- 秘密情報・トークン・マシン固有パスを設定値に書かない。

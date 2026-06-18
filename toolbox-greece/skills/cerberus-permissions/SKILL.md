---
name: cerberus-permissions
description: Codex の実行権限を管理するため、`~/.codex/config.toml` の sandbox_mode / approval_policy / network_access / writable_roots / profiles / projects を作成・更新し、安全な実行境界を一定に保つときに使う。権限の粒度調整、プロジェクト単位の信頼設定、破壊的操作や外向き通信の抑制に向いている。
---

# cerberus-permissions

Codex が実行できる範囲を定め、`~/.codex/config.toml` に権限境界を集約するために使う。ユーザーが用途に応じて粒度を選べるよう、設定の引き出しと分類基準を持つ。

Codex の権限は、Claude Code のような「コマンド単位の allow / ask / deny リスト」ではなく、**サンドボックス（書き込み・ネットワークの境界）** と **承認ポリシー（いつ人間に確認するか）** の組み合わせで決まる。この2軸を中心に粒度を選ぶ。

## 重視すること

- 書き込み・ネットワーク・破壊操作の境界を、サンドボックスで確実に絞る
- 承認ポリシーで「いつ止めて確認するか」を決め、危険操作を素通りさせない
- グローバル既定とプロジェクト単位の信頼を混ぜない
- 秘密情報やマシン固有の値を設定に残さない
- 絞りすぎて作業が止まらないよう、緩める方向は実運用で足す前提にする
- ユーザーが望む粒度（粗め / 標準 / 厳格）を確認し、過不足なく設定する

## config.toml はコメント可（JSON との違い）

- `config.toml` は TOML なので `#` でコメントを書ける。`settings.json` と違い、説明を同じファイルに残せる。
- ただしルールが増えると config.toml が読みづらくなるため、方針の意味・層・理由は `PERMISSIONS.md` に対応表として残すとよい。
- 雛形は `templates/PERMISSIONS.md`（このスキル内）にある。これを `~/.codex/PERMISSIONS.md` などへコピーし、実設定に合わせて書き換える。
- config.toml に `#` で要点を、`PERMISSIONS.md` に詳細を、と役割を分けると同期ずれを抑えやすい。

## 設定の層と優先順位

- `~/.codex/config.toml`（トップレベル）: 全プロジェクト共通の既定。最小限の安全策を置く。
- `[projects."<絶対パス>"]`: プロジェクト単位の信頼設定（`trust_level` など）。リポジトリごとの緩和はここに置く。
- `[profiles.<名前>]`: 用途別プリセット。`--profile <名前>` で切り替える。
- 競合時は、起動時に選んだ profile とプロジェクト設定がトップレベル既定を上書きする。最も危険な操作ほど既定側を厳しくしておく。

## 主要な設定キー

- `sandbox_mode`: 実行サンドボックス。
  - `read-only`: 読み取りのみ。書き込み不可。
  - `workspace-write`: cwd（と一時領域）への書き込みを許可。既定はネットワーク遮断。
  - `danger-full-access`: 制限なし。原則使わない。
- `approval_policy`: 人間へ確認を求める条件。
  - `untrusted`: 信頼済み以外は都度確認。最も慎重。
  - `on-request`: 必要時に Codex 側から確認を求める（標準）。
  - `on-failure`: サンドボックス内で失敗したときだけ昇格確認。
  - `never`: 確認しない。自動実行向け（範囲を絞った上で）。
- `[sandbox_workspace_write]`:
  - `network_access`: 外向き通信の可否（既定 false）。
  - `writable_roots`: 追加で書き込みを許すディレクトリ（cwd 外を広げるときだけ）。
  - `exclude_tmpdir_env_var` / `exclude_slash_tmp`: 一時領域の扱い。
- `[projects."<絶対パス>"]`:
  - `trust_level = "trusted"`: そのリポジトリを信頼し、確認を減らす。信頼できる作業ディレクトリだけに付ける。

## 粒度プリセット（ユーザーに選んでもらう）

- **粗め**: `sandbox_mode = "workspace-write"`、`approval_policy = "on-failure"`、`network_access = true`。確認が少なく速い。信頼済みリポジトリ向け。
- **標準（既定）**: `sandbox_mode = "workspace-write"`、`approval_policy = "on-request"`、`network_access = false`。書き込みは cwd 内、外向きは確認、危険操作は昇格時に確認。
- **厳格**: `sandbox_mode = "read-only"`（書き込みが要るなら `workspace-write` ＋ `writable_roots` で対象を限定）、`approval_policy = "untrusted"`、`network_access = false`。確認は増えるが事故が起きにくい。

迷う場合は「標準」を提示し、ネットワークと書き込み範囲だけ個別に詰める。

## 設定例

```toml
# 全プロジェクト共通の安全な既定（標準プリセット）
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
network_access = false

# 速く回したい信頼済みリポジトリだけ緩める
[projects."/Users/me/work/trusted-repo"]
trust_level = "trusted"

# 用途別プリセット
[profiles.strict]
approval_policy = "untrusted"
sandbox_mode = "read-only"

[profiles.auto]
approval_policy = "never"
sandbox_mode = "workspace-write"
```

## 手順

1. 既存の `~/.codex/config.toml` を読み、現在の `sandbox_mode` / `approval_policy` / ネットワーク設定 / projects / profiles を把握する。
2. 望む粒度（粗め / 標準 / 厳格）と、説明の持たせ方（config.toml の `#` コメント / `PERMISSIONS.md` / 両方）をユーザーに確認する。
3. このリポジトリ固有の事情（外向き通信の要否、cwd 外への書き込みの要否、自動実行の要否）を洗い出す。
4. トップレベルに安全な既定を置き、緩める必要があるリポジトリだけ `[projects."<絶対パス>"]` の `trust_level` で個別に許可する。
5. 自動実行や厳格運用が要るなら `[profiles.<名前>]` を用意し、`--profile` で切り替える前提にする。
6. `PERMISSIONS.md` を用意する。新規なら `templates/PERMISSIONS.md` をコピーし、リポジトリ名・粒度・最終更新・実設定に合わせて書き換える。既存なら config.toml の差分に合わせて該当行を更新する（同期ずれを残さない）。
7. 変更後に TOML として読めること（`codex` を起動できる、または TOML パーサで検証）と、想定する操作の許否を確認する。

## 判断基準

- 全プロジェクトで安全な既定（書き込み制限、ネットワーク遮断、危険操作の確認）はトップレベルに置く。
- そのリポジトリでしか使わない緩和（信頼、自動実行）は `[projects]` か `[profiles]` に分ける。
- cwd 外へ書き込みたいときだけ `writable_roots` を足す。安易に広げない。
- `network_access = true` は必要なリポジトリ・プロファイルに限定する。
- `danger-full-access` と `approval_policy = "never"` の併用は、隔離環境かつ明示指示がある場合のみにする。

## 注意

- `~/.codex/config.toml` は cwd 外のユーザー設定なので、変更前に必ず確認する。既存設定の破壊的な書き換えは事前確認する。
- 秘密情報、トークン、マシン固有パスを設定値に書かない。
- 広すぎる制限で必要な作業まで止めないか、緩すぎる設定で危険操作が素通りしないかを両面で確認する。
- プロジェクトの `trust_level = "trusted"` は、内容を信頼できる作業ディレクトリにだけ付ける。

## 出力

- 現在の権限構成の短い評価
- 選んだ粒度プリセットと、その理由
- トップレベル / projects / profiles に置く設定の分類と理由
- 作成・更新する設定（`config.toml` と、必要なら `PERMISSIONS.md`）の最小差分
- 確認した許否と残る注意点

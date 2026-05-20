# Agents Validation

## Setup
```bash
python3 -m pip install -e '.[dev]'
```

## Required Test
```bash
python3 -m pytest -q
```

## Optional Check
以下のスクリプトが存在する場合のみ実行する。

```bash
bash toolbox/skills/bootstrap-repository/scripts/check-agents-md.sh AGENTS.md
```

## Toolbox Operations
```bash
python3 scripts/toolbox-manager.py status
python3 scripts/toolbox-manager.py copy --name greece
python3 scripts/toolbox-manager.py apply --toolbox toolbox --dry-run
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
```

## Validation Policy
- 最低でも `python3 -m pytest -q` は実行する。
- format や lint の専用コマンドが未定義なら、その旨を報告する。
- CLI や設定適用処理を変えた場合は、必要に応じて `toolbox-manager.py` の関連コマンドも確認する。
- ドキュメントのみの変更でも、実装と矛盾していないことを確認する。

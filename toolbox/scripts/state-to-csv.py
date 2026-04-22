#!/usr/bin/env python3
"""
state-to-csv.py
project-state.json から spawn_agents_on_csv 用 CSV を生成。
pending かつ依存解決済みの Feature のみ出力。

Usage:
    python3 state-to-csv.py [state_path] [output_path]

    state_path:  project-state.json へのパス（デフォルト: specs/project-state.json）
    output_path: 出力 CSV パス（デフォルト: ~/.codex/features.csv）

依存: Python 3 のみ（API キー不要）
"""
import json
import csv
import sys
import os

state_path = sys.argv[1] if len(sys.argv) > 1 else "specs/project-state.json"
output_path = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/.codex/features.csv")

if not os.path.isfile(state_path):
    print(f"ERROR: state file not found: {state_path}", file=sys.stderr)
    sys.exit(1)

with open(state_path) as f:
    state = json.load(f)

features = state.get("features", [])
done = {x["id"] for x in features if x["status"] == "done"}
ready = [
    x for x in features
    if x["status"] == "pending"
    and all(d in done for d in x.get("depends_on", []))
]

os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)

with open(output_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["feature_id", "feature_name", "wave", "feature_dir"])
    writer.writeheader()
    for feat in ready:
        writer.writerow({
            "feature_id": feat["id"],
            "feature_name": feat.get("name", feat["id"]),
            "wave": feat.get("wave", 1),
            "feature_dir": f"specs/features/{feat.get('name', feat['id'])}",
        })

print(f"生成: {output_path} ({len(ready)} Features)")

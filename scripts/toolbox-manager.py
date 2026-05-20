#!/usr/bin/env python3
"""Copy toolbox snapshots and apply managed Codex settings safely."""

from __future__ import annotations

import argparse
import filecmp
import fnmatch
import json
import os
import re
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CODEX_HOME = Path.home() / ".codex"
MANIFEST_NAME = ".kyarameru-tool-box-manifest.json"

MANAGED_ENTRIES = (
    "config.toml",
    "AGENTS.md",
    "skills",
    "agents",
    "hooks",
    "prompts",
    "plugins",
    "mcp",
    "memories",
)

EXCLUDED_NAMES = {
    "auth.json",
    "history.jsonl",
    "session_index.jsonl",
    "installation_id",
    ".gitkeep",
    "log",
    "sessions",
    "shell_snapshots",
    "tmp",
    ".tmp",
    "cache",
    "vendor_imports",
    "models_cache.json",
    ".codex-global-state.json",
}

EXCLUDED_PATTERNS = ("*.sqlite", "*.sqlite-*")
TOOLBOX_RE = re.compile(r"^toolbox(\d+)$")
TOOLBOX_NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")


@dataclass(frozen=True)
class ApplyItem:
    source: Path
    destination: Path
    relative: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Manage kyarameru toolbox snapshots and ~/.codex application."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=REPO_ROOT,
        help=argparse.SUPPRESS,
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    copy_parser = subparsers.add_parser(
        "copy", help="Copy toolbox/ to a named toolbox-*/ or the next toolboxN/."
    )
    copy_parser.add_argument("--source", default="toolbox", help="Source toolbox directory.")
    copy_parser.add_argument(
        "--name",
        help="Copy destination name. 'greece' creates toolbox-greece/.",
    )
    copy_parser.add_argument("--dry-run", action="store_true", help="Show planned copy only.")

    apply_parser = subparsers.add_parser(
        "apply", help="Apply a toolbox to a Codex home directory."
    )
    add_apply_status_args(apply_parser)
    apply_parser.add_argument(
        "--yes",
        action="store_true",
        help="Allow overwriting existing managed files without interactive confirmation.",
    )
    backup_group = apply_parser.add_mutually_exclusive_group()
    backup_group.add_argument(
        "--backup",
        action="store_true",
        help="Back up overwritten destinations to backup/<timestamp>/.",
    )
    backup_group.add_argument(
        "--no-backup",
        action="store_true",
        help="Overwrite without creating backups.",
    )
    backup_group.add_argument(
        "--safe",
        action="store_true",
        help="Overwrite without prompting and create backups.",
    )
    backup_group.add_argument(
        "--force",
        action="store_true",
        help="Overwrite without prompting or creating backups.",
    )
    apply_parser.add_argument("--dry-run", action="store_true", help="Show planned changes only.")

    status_parser = subparsers.add_parser(
        "status", help="Show application status for a toolbox and Codex home."
    )
    add_apply_status_args(status_parser)

    return parser.parse_args()


def add_apply_status_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--toolbox",
        default="toolbox",
        help="Toolbox directory to use. Defaults to toolbox.",
    )
    parser.add_argument(
        "--codex-home",
        type=Path,
        default=DEFAULT_CODEX_HOME,
        help="Codex home directory. Defaults to ~/.codex.",
    )


def resolve_repo_path(repo_root: Path, value: str | Path) -> Path:
    path = Path(value).expanduser()
    if path.is_absolute():
        return path
    return repo_root / path


def next_toolbox_path(repo_root: Path) -> Path:
    used = set()
    for child in repo_root.iterdir():
        if not child.is_dir():
            continue
        match = TOOLBOX_RE.match(child.name)
        if match:
            used.add(int(match.group(1)))
    number = 1
    while number in used:
        number += 1
    return repo_root / f"toolbox{number}"


def named_toolbox_path(repo_root: Path, name: str) -> Path:
    normalized = name.strip()
    if normalized.startswith("toolbox-"):
        suffix = normalized[len("toolbox-") :]
    else:
        suffix = normalized
    if not suffix or not TOOLBOX_NAME_RE.fullmatch(suffix):
        raise SystemExit(
            "Toolbox name must match [a-z0-9][a-z0-9-]* and becomes toolbox-<name>."
        )
    return repo_root / f"toolbox-{suffix}"


def should_exclude(path: Path) -> bool:
    parts = path.parts
    if any(part in EXCLUDED_NAMES for part in parts):
        return True
    return any(fnmatch.fnmatch(path.name, pattern) for pattern in EXCLUDED_PATTERNS)


def iter_apply_items(toolbox: Path, codex_home: Path) -> list[ApplyItem]:
    items: list[ApplyItem] = []
    for entry_name in MANAGED_ENTRIES:
        source = toolbox / entry_name
        if not source.exists():
            continue
        if should_exclude(Path(entry_name)):
            continue
        items.append(
            ApplyItem(
                source=source,
                destination=codex_home / entry_name,
                relative=entry_name,
            )
        )
    return items


def collect_excluded(toolbox: Path) -> list[str]:
    excluded: list[str] = []
    for root, dirs, files in os.walk(toolbox):
        root_path = Path(root)
        rel_root = root_path.relative_to(toolbox)
        kept_dirs = []
        for directory in dirs:
            rel_path = rel_root / directory
            if should_exclude(rel_path):
                excluded.append(rel_path.as_posix())
            else:
                kept_dirs.append(directory)
        dirs[:] = kept_dirs
        for filename in files:
            rel_path = rel_root / filename
            if should_exclude(rel_path):
                excluded.append(rel_path.as_posix())
    return sorted(excluded)


def paths_equal(source: Path, destination: Path) -> bool:
    if not destination.exists():
        return False
    if source.is_file() and destination.is_file():
        return filecmp.cmp(source, destination, shallow=False)
    if source.is_dir() and destination.is_dir():
        source_files = sorted(
            p.relative_to(source)
            for p in source.rglob("*")
            if p.is_file() and not should_exclude(p.relative_to(source))
        )
        return all(
            (destination / rel_path).is_file()
            and filecmp.cmp(source / rel_path, destination / rel_path, shallow=False)
            for rel_path in source_files
        )
    return False


def conflicting_items(items: list[ApplyItem]) -> list[ApplyItem]:
    return [
        item
        for item in items
        if item.destination.exists() and not paths_equal(item.source, item.destination)
    ]


def prompt_yes_no(message: str, *, default: bool = False) -> bool:
    suffix = " [Y/n] " if default else " [y/N] "
    answer = input(message + suffix).strip().lower()
    if not answer:
        return default
    return answer in {"y", "yes"}


def require_apply_confirmation(
    conflicts: list[ApplyItem],
    *,
    yes: bool,
    backup: bool,
    no_backup: bool,
    dry_run: bool,
) -> bool:
    if not conflicts or dry_run:
        return backup
    if yes:
        if not backup and not no_backup:
            raise SystemExit(
                "Overwriting existing files requires --backup or --no-backup with --yes."
            )
        return backup
    if not sys.stdin.isatty():
        raise SystemExit(
            "Refusing to overwrite existing files in non-interactive mode. "
            "Use --yes with --backup or --no-backup."
        )
    print("Existing managed files will be overwritten:")
    for item in conflicts:
        print(f"  {item.relative}")
    if not prompt_yes_no("Continue applying these changes?"):
        raise SystemExit("Apply cancelled.")
    if backup or no_backup:
        return backup
    return prompt_yes_no("Create backups before overwriting?", default=True)


def copy_dir_contents(source: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    for child in source.iterdir():
        rel_path = child.relative_to(source)
        if should_exclude(rel_path):
            continue
        target = destination / child.name
        if child.is_dir():
            if target.exists() and not target.is_dir():
                target.unlink()
            copy_dir_contents(child, target)
        else:
            if target.exists() and target.is_dir():
                shutil.rmtree(target)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(child, target)


def copy_path(source: Path, destination: Path) -> None:
    if source.is_dir():
        if destination.exists() and not destination.is_dir():
            destination.unlink()
        copy_dir_contents(source, destination)
    else:
        if destination.exists() and destination.is_dir():
            shutil.rmtree(destination)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def backup_destination(codex_home: Path, item: ApplyItem, timestamp: str) -> Path:
    backup_root = codex_home / "backup" / timestamp
    backup_path = backup_root / item.relative
    backup_path.parent.mkdir(parents=True, exist_ok=True)
    if item.destination.is_dir():
        shutil.copytree(item.destination, backup_path, symlinks=True)
    else:
        shutil.copy2(item.destination, backup_path)
    return backup_path


def write_manifest(codex_home: Path, toolbox: Path, items: list[ApplyItem]) -> None:
    manifest = {
        "managed_by": "kyarameru-tool-box",
        "source_toolbox": str(toolbox),
        "applied_at": datetime.now(timezone.utc).isoformat(),
        "entries": sorted(item.relative for item in items),
    }
    codex_home.mkdir(parents=True, exist_ok=True)
    manifest_path = codex_home / MANIFEST_NAME
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")


def command_copy(args: argparse.Namespace) -> int:
    repo_root = args.repo_root.resolve()
    source = resolve_repo_path(repo_root, args.source)
    if not source.is_dir():
        raise SystemExit(f"Source toolbox does not exist: {source}")
    destination = (
        named_toolbox_path(repo_root, args.name) if args.name else next_toolbox_path(repo_root)
    )
    if destination.exists():
        raise SystemExit(f"Destination toolbox already exists: {destination}")
    print(f"Copy source: {source.relative_to(repo_root)}")
    print(f"Copy destination: {destination.relative_to(repo_root)}")
    if args.dry_run:
        print("Dry run: no files changed.")
        return 0
    shutil.copytree(source, destination, symlinks=True)
    print(f"Created {destination.relative_to(repo_root)}")
    return 0


def command_apply(args: argparse.Namespace) -> int:
    repo_root = args.repo_root.resolve()
    toolbox = resolve_repo_path(repo_root, args.toolbox)
    codex_home = args.codex_home.expanduser()
    if not toolbox.is_dir():
        raise SystemExit(f"Toolbox does not exist: {toolbox}")

    items = iter_apply_items(toolbox, codex_home)
    excluded = collect_excluded(toolbox)
    conflicts = conflicting_items(items)
    use_backup = require_apply_confirmation(
        conflicts,
        yes=args.yes or args.safe or args.force,
        backup=args.backup or args.safe,
        no_backup=args.no_backup or args.force,
        dry_run=args.dry_run,
    )

    print(f"Apply source: {toolbox}")
    print(f"Codex home: {codex_home}")
    print("Managed entries:")
    for item in items:
        action = "overwrite" if item.destination.exists() else "create"
        print(f"  {action}: {item.relative}")
    if conflicts and use_backup:
        print("Backup planned for overwritten entries.")
    if excluded:
        print("Excluded entries:")
        for rel_path in excluded:
            print(f"  {rel_path}")

    if args.dry_run:
        print("Dry run: no files changed.")
        return 0

    codex_home.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    for item in items:
        if item.destination.exists() and use_backup:
            backup_destination(codex_home, item, timestamp)
        copy_path(item.source, item.destination)
    write_manifest(codex_home, toolbox, items)
    print(f"Wrote manifest: {codex_home / MANIFEST_NAME}")
    return 0


def command_status(args: argparse.Namespace) -> int:
    repo_root = args.repo_root.resolve()
    toolbox = resolve_repo_path(repo_root, args.toolbox)
    codex_home = args.codex_home.expanduser()
    if not toolbox.is_dir():
        raise SystemExit(f"Toolbox does not exist: {toolbox}")
    items = iter_apply_items(toolbox, codex_home)
    manifest_path = codex_home / MANIFEST_NAME
    print(f"Toolbox: {toolbox}")
    print(f"Codex home: {codex_home}")
    print(f"Manifest: {'present' if manifest_path.exists() else 'missing'}")
    for item in items:
        if not item.destination.exists():
            state = "missing"
        elif paths_equal(item.source, item.destination):
            state = "current"
        else:
            state = "different"
        print(f"{state}: {item.relative}")
    return 0


def main() -> int:
    args = parse_args()
    if args.command == "copy":
        return command_copy(args)
    if args.command == "apply":
        return command_apply(args)
    if args.command == "status":
        return command_status(args)
    raise SystemExit(f"Unknown command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())

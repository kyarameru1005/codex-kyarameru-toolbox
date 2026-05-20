import json
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "toolbox-manager.py"


def run_manager(tmp_path, *args, check=True):
    command = [
        sys.executable,
        str(SCRIPT),
        "--repo-root",
        str(tmp_path),
        *args,
    ]
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    if check and result.returncode != 0:
        raise AssertionError(
            f"command failed: {command}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def test_copy_uses_next_available_toolbox_number(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'a'\n")
    (tmp_path / "toolbox1").mkdir()

    result = run_manager(tmp_path, "copy")

    assert result.returncode == 0
    assert (tmp_path / "toolbox2" / "config.toml").read_text() == "model = 'a'\n"
    assert "Created toolbox2" in result.stdout


def test_copy_can_use_named_toolbox_destination(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'a'\n")

    result = run_manager(tmp_path, "copy", "--name", "greece")

    assert result.returncode == 0
    assert (tmp_path / "toolbox-greece" / "config.toml").read_text() == "model = 'a'\n"
    assert "Created toolbox-greece" in result.stdout


def test_apply_can_select_named_toolbox(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'base'\n")
    write(tmp_path / "toolbox-greece" / "config.toml", "model = 'two'\n")
    codex_home = tmp_path / "codex-home"

    run_manager(
        tmp_path,
        "apply",
        "--toolbox",
        "toolbox-greece",
        "--codex-home",
        str(codex_home),
        "--yes",
        "--no-backup",
    )

    assert (codex_home / "config.toml").read_text() == "model = 'two'\n"


def test_apply_excludes_runtime_and_secret_state(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'base'\n")
    write(tmp_path / "toolbox" / "auth.json", "{}\n")
    write(tmp_path / "toolbox" / "history.jsonl", "{}\n")
    write(tmp_path / "toolbox" / "skills" / ".gitkeep", "")
    write(tmp_path / "toolbox" / "skills" / "demo" / "SKILL.md", "# Demo\n")
    write(tmp_path / "toolbox" / "skills" / "demo" / "state.sqlite", "db")
    write(tmp_path / "toolbox" / "sessions" / "rollout.jsonl", "{}\n")
    write(tmp_path / "toolbox" / "cache" / "tool.json", "{}\n")
    codex_home = tmp_path / "codex-home"

    run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        "--yes",
        "--no-backup",
    )

    assert (codex_home / "config.toml").exists()
    assert (codex_home / "skills").is_dir()
    assert (codex_home / "skills" / "demo" / "SKILL.md").exists()
    assert not (codex_home / "skills" / ".gitkeep").exists()
    assert not (codex_home / "auth.json").exists()
    assert not (codex_home / "history.jsonl").exists()
    assert not (codex_home / "skills" / "demo" / "state.sqlite").exists()
    assert not (codex_home / "sessions").exists()
    assert not (codex_home / "cache").exists()


def test_apply_backs_up_overwritten_files(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'new'\n")
    codex_home = tmp_path / "codex-home"
    write(codex_home / "config.toml", "model = 'old'\n")

    run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        "--yes",
        "--backup",
    )

    backups = list((codex_home / "backup").glob("*"))
    assert len(backups) == 1
    assert (backups[0] / "config.toml").read_text() == "model = 'old'\n"
    assert (codex_home / "config.toml").read_text() == "model = 'new'\n"


def test_safe_alias_backs_up_and_overwrites(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'new'\n")
    codex_home = tmp_path / "codex-home"
    write(codex_home / "config.toml", "model = 'old'\n")

    run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        "--safe",
    )

    backups = list((codex_home / "backup").glob("*"))
    assert len(backups) == 1
    assert (backups[0] / "config.toml").read_text() == "model = 'old'\n"
    assert (codex_home / "config.toml").read_text() == "model = 'new'\n"


def test_force_alias_overwrites_without_backup(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'new'\n")
    codex_home = tmp_path / "codex-home"
    write(codex_home / "config.toml", "model = 'old'\n")

    run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        "--force",
    )

    assert not (codex_home / "backup").exists()
    assert (codex_home / "config.toml").read_text() == "model = 'new'\n"


def test_dry_run_does_not_change_files(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'new'\n")
    codex_home = tmp_path / "codex-home"
    write(codex_home / "config.toml", "model = 'old'\n")

    result = run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        "--dry-run",
    )

    assert result.returncode == 0
    assert (codex_home / "config.toml").read_text() == "model = 'old'\n"
    assert not (codex_home / ".kyarameru-tool-box-manifest.json").exists()
    assert "Dry run: no files changed." in result.stdout


def test_noninteractive_overwrite_requires_explicit_yes(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'new'\n")
    codex_home = tmp_path / "codex-home"
    write(codex_home / "config.toml", "model = 'old'\n")

    result = run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        check=False,
    )

    assert result.returncode != 0
    assert "Refusing to overwrite" in result.stderr
    assert (codex_home / "config.toml").read_text() == "model = 'old'\n"


def test_manifest_tracks_only_managed_entries(tmp_path):
    write(tmp_path / "toolbox" / "config.toml", "model = 'base'\n")
    write(tmp_path / "toolbox" / "skills" / "demo" / "SKILL.md", "# Demo\n")
    write(tmp_path / "toolbox" / "auth.json", "{}\n")
    codex_home = tmp_path / "codex-home"

    run_manager(
        tmp_path,
        "apply",
        "--codex-home",
        str(codex_home),
        "--yes",
        "--no-backup",
    )

    manifest = json.loads((codex_home / ".kyarameru-tool-box-manifest.json").read_text())
    assert manifest["managed_by"] == "kyarameru-tool-box"
    assert manifest["entries"] == ["config.toml", "skills"]

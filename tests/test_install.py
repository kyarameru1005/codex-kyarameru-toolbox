from __future__ import annotations

import os
import importlib.util
import json
import subprocess
import sys
from pathlib import Path


def load_module():
    script_path = Path(__file__).resolve().parents[1] / "scripts" / "install.py"
    spec = importlib.util.spec_from_file_location("installer", script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def create_source_tree(root: Path) -> None:
    (root / "toolbox" / "skills" / "plan-worker").mkdir(parents=True)
    (root / "toolbox" / "skills" / "mcp-worker").mkdir(parents=True)
    (root / "toolbox" / "agents").mkdir(parents=True)
    (root / "toolbox" / "hooks").mkdir(parents=True)
    (root / "toolbox" / "prompts").mkdir(parents=True)

    (root / "toolbox" / "skills" / "plan-worker" / "SKILL.md").write_text("plan", encoding="utf-8")
    (root / "toolbox" / "skills" / "mcp-worker" / "SKILL.md").write_text("mcp", encoding="utf-8")
    (root / "toolbox" / "agents" / "harness-worker.toml").write_text("name = \"harness-worker\"\n", encoding="utf-8")
    (root / "toolbox" / "hooks" / "preflight.sh").write_text("#!/bin/sh\n", encoding="utf-8")
    (root / "toolbox" / "AGENTS.md").write_text("# global agents\n", encoding="utf-8")


def test_iter_source_entries_maps_to_codex_home(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)

    fake_home = tmp_path / "home"
    entries = installer.iter_source_entries(root=tmp_path, home=fake_home)

    targets = {e.target for e in entries}
    assert fake_home / ".codex" / "skills" / "plan-worker" in targets
    assert fake_home / ".codex" / "skills" / "mcp-worker" in targets
    assert fake_home / ".codex" / "agents" / "harness-worker.toml" in targets
    assert fake_home / ".codex" / "hooks" / "preflight.sh" in targets
    assert fake_home / ".codex" / "AGENTS.md" in targets


def test_install_copy_and_manifest(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"

    rc = installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home)
    assert rc == 0

    plan_skill = fake_home / ".codex" / "skills" / "plan-worker" / "SKILL.md"
    assert plan_skill.exists()
    assert plan_skill.read_text(encoding="utf-8") == "plan"
    harness_worker = fake_home / ".codex" / "agents" / "harness-worker.toml"
    assert harness_worker.exists()
    assert harness_worker.read_text(encoding="utf-8") == 'name = "harness-worker"\n'
    global_agents = fake_home / ".codex" / "AGENTS.md"
    assert global_agents.exists()
    assert global_agents.read_text(encoding="utf-8") == "# global agents\n"

    manifest = fake_home / ".codex" / installer.MANIFEST_FILENAME
    assert manifest.exists()
    data = json.loads(manifest.read_text(encoding="utf-8"))
    assert data["app"] == installer.APP_NAME
    assert str(fake_home / ".codex" / "skills" / "plan-worker") in data["paths"]
    assert str(fake_home / ".codex" / "agents" / "harness-worker.toml") in data["paths"]
    assert str(fake_home / ".codex" / "AGENTS.md") in data["paths"]


def test_unmanaged_target_is_not_overwritten(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"

    unmanaged = fake_home / ".codex" / "hooks" / "preflight.sh"
    unmanaged.parent.mkdir(parents=True, exist_ok=True)
    unmanaged.write_text("custom", encoding="utf-8")

    installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home)
    assert unmanaged.read_text(encoding="utf-8") == "custom"


def test_existing_agents_is_backed_up_and_replaced_on_copy(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"
    existing_agents = fake_home / ".codex" / "AGENTS.md"
    existing_agents.parent.mkdir(parents=True, exist_ok=True)
    existing_agents.write_text("# custom agents\n", encoding="utf-8")

    installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home)

    assert existing_agents.read_text(encoding="utf-8") == "# global agents\n"
    backups = sorted((fake_home / ".codex").glob("AGENTS.md.bak.*"))
    assert len(backups) == 1
    assert backups[0].read_text(encoding="utf-8") == "# custom agents\n"


def test_existing_agents_is_backed_up_and_replaced_on_link(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"
    existing_agents = fake_home / ".codex" / "AGENTS.md"
    existing_agents.parent.mkdir(parents=True, exist_ok=True)
    existing_agents.write_text("# custom agents\n", encoding="utf-8")

    installer.install(mode="link", dry_run=False, root=tmp_path, home=fake_home)

    assert existing_agents.is_symlink()
    assert existing_agents.resolve() == (tmp_path / "toolbox" / "AGENTS.md").resolve()
    backups = sorted((fake_home / ".codex").glob("AGENTS.md.bak.*"))
    assert len(backups) == 1
    assert backups[0].read_text(encoding="utf-8") == "# custom agents\n"


def test_dry_run_keeps_filesystem_clean(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"

    installer.install(mode="copy", dry_run=True, root=tmp_path, home=fake_home)

    assert not (fake_home / ".codex" / "skills" / "plan-worker").exists()
    assert not (fake_home / ".codex" / installer.MANIFEST_FILENAME).exists()
    assert not (fake_home / ".codex" / "AGENTS.md").exists()
    assert not list((fake_home / ".codex").glob("AGENTS.md.bak.*"))


def test_update_removes_stale_managed_paths(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"

    installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home)
    stale_skill_dir = fake_home / ".codex" / "skills" / "mcp-worker"
    assert stale_skill_dir.exists()

    shutil_target = tmp_path / "toolbox" / "skills" / "mcp-worker"
    if shutil_target.exists():
        for child in sorted(shutil_target.rglob("*"), reverse=True):
            if child.is_file() or child.is_symlink():
                child.unlink()
            elif child.is_dir():
                child.rmdir()
        shutil_target.rmdir()

    installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home, cleanup_stale=True)
    assert not stale_skill_dir.exists()
    assert (fake_home / ".codex" / "skills" / "plan-worker").exists()


def test_update_dry_run_keeps_stale_managed_paths(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"

    installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home)
    stale_skill_dir = fake_home / ".codex" / "skills" / "mcp-worker"
    assert stale_skill_dir.exists()

    source_stale = tmp_path / "toolbox" / "skills" / "mcp-worker"
    source_stale.joinpath("SKILL.md").unlink()
    source_stale.rmdir()

    installer.install(mode="copy", dry_run=True, root=tmp_path, home=fake_home, cleanup_stale=True)
    assert stale_skill_dir.exists()


def test_uninstall_removes_only_managed(tmp_path: Path):
    installer = load_module()
    create_source_tree(tmp_path)
    fake_home = tmp_path / "home"

    installer.install(mode="copy", dry_run=False, root=tmp_path, home=fake_home)

    keep_file = fake_home / ".codex" / "hooks" / "keep.sh"
    keep_file.parent.mkdir(parents=True, exist_ok=True)
    keep_file.write_text("keep", encoding="utf-8")
    agents_backup = fake_home / ".codex" / "AGENTS.md.bak.manual"
    agents_backup.write_text("# backup\n", encoding="utf-8")

    installer.uninstall(dry_run=False, home=fake_home)

    assert keep_file.exists()
    assert agents_backup.exists()
    assert not (fake_home / ".codex" / "skills" / "plan-worker").exists()
    assert not (fake_home / ".codex" / "AGENTS.md").exists()
    assert not (fake_home / ".codex" / installer.MANIFEST_FILENAME).exists()


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def setup_policy_repo(tmp_path: Path, workflow_content: str) -> None:
    policy_script = Path(__file__).resolve().parents[1] / "scripts" / "policy-check.sh"
    write_file(
        tmp_path / "AGENTS.md",
        "# AGENTS\n目的\n優先\n応答\n実行\nGit\nログ\n命名\nkebab-case\nPR本文を正本とする\n",
    )
    write_file(
        tmp_path / "toolbox" / "AGENTS.md",
        "# AGENTS\n目的\n優先\n応答\n実行\nGit\nログ\n命名\nkebab-case\nPR本文を正本とする\n",
    )
    write_file(
        tmp_path / ".github" / "workflows" / "tests.yml",
        workflow_content,
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "bootstrap-repository" / "scripts" / "check-agents-md.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"[OK] mock check: $1\"\n",
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "skill-validation-worker" / "scripts" / "check-skill.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"[OK] mock skill check: $1\"\n",
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "ci-failure-triage-worker" / "scripts" / "triage-pr-ci.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"[OK] mock triage: $1\"\n",
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "pr-quality-gate-worker" / "scripts" / "check-pr-quality.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"[OK] mock quality gate\"\n",
    )
    write_file(
        tmp_path / "toolbox" / "agents" / "harness-worker.toml",
        "name = \"harness-worker\"\n",
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "harness-report-writer" / "SKILL.md",
        "# harness-report-writer\n",
    )
    write_file(
        tmp_path / "docs" / "pr-template.md",
        "## 目的\n- test\n\n## 主な変更点\n- test\n\n## 検証結果\n- test\n",
    )
    write_file(
        tmp_path / "scripts" / "create-pr.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"mock\"\n",
    )
    write_file(
        tmp_path / "scripts" / "harness.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\nbash scripts/secret-check.sh\n",
    )
    write_file(
        tmp_path / "scripts" / "secret-check.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"[OK] mock secret check\"\n",
    )
    write_file(
        tmp_path / "scripts" / "gitleaks.toml",
        "[extend]\nuseDefault = true\n",
    )
    write_file(tmp_path / "scripts" / "policy-check.sh", policy_script.read_text(encoding="utf-8"))
    subprocess.run(["chmod", "+x", str(tmp_path / "scripts" / "create-pr.sh")], check=True)
    subprocess.run(["chmod", "+x", str(tmp_path / "scripts" / "harness.sh")], check=True)
    subprocess.run(["chmod", "+x", str(tmp_path / "scripts" / "secret-check.sh")], check=True)
    subprocess.run(["chmod", "+x", str(tmp_path / "scripts" / "policy-check.sh")], check=True)
    subprocess.run(
        ["chmod", "+x", str(tmp_path / "toolbox" / "skills" / "bootstrap-repository" / "scripts" / "check-agents-md.sh")],
        check=True,
    )
    subprocess.run(
        ["chmod", "+x", str(tmp_path / "toolbox" / "skills" / "skill-validation-worker" / "scripts" / "check-skill.sh")],
        check=True,
    )
    subprocess.run(
        ["chmod", "+x", str(tmp_path / "toolbox" / "skills" / "ci-failure-triage-worker" / "scripts" / "triage-pr-ci.sh")],
        check=True,
    )
    subprocess.run(
        ["chmod", "+x", str(tmp_path / "toolbox" / "skills" / "pr-quality-gate-worker" / "scripts" / "check-pr-quality.sh")],
        check=True,
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "harness-report-writer" / "SKILL.md",
        "# harness-report-writer\n\n目的: test\n\n## 推奨トリガー\n- test\n\n## 出力\n- test\n",
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "orchestrator-worker" / "SKILL.md",
        "# orchestrator-worker\n\n目的: test\n\n## 推奨トリガー\n- test\n\n## 出力\n- test\n",
    )
    write_file(
        tmp_path / "toolbox" / "skills" / "orchestrator-worker" / "scripts" / "update-task-state.sh",
        "#!/usr/bin/env bash\nset -euo pipefail\necho \"[OK] mock update state\"\n",
    )
    subprocess.run(
        ["chmod", "+x", str(tmp_path / "toolbox" / "skills" / "orchestrator-worker" / "scripts" / "update-task-state.sh")],
        check=True,
    )


def test_policy_check_passes_with_required_files_and_workflow(tmp_path: Path):
    setup_policy_repo(
        tmp_path,
        "name: tests\non:\n  push:\n  pull_request:\njobs:\n  tests:\n    runs-on: ubuntu-latest\n  secret-scan:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/secret-check.sh --patterns-only\n  harness:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/harness.sh\n  agents-policy:\n    runs-on: ubuntu-latest\n",
    )

    result = subprocess.run(
        ["bash", "scripts/policy-check.sh"],
        cwd=tmp_path,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0
    assert "[DONE] policy checks passed" in result.stdout


def test_policy_check_fails_when_workflow_is_missing(tmp_path: Path):
    setup_policy_repo(
        tmp_path,
        "name: tests\non:\n  push:\n  pull_request:\njobs:\n  tests:\n    runs-on: ubuntu-latest\n  secret-scan:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/secret-check.sh --patterns-only\n  harness:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/harness.sh\n  agents-policy:\n    runs-on: ubuntu-latest\n",
    )
    (tmp_path / ".github" / "workflows" / "tests.yml").unlink()

    result = subprocess.run(
        ["bash", "scripts/policy-check.sh"],
        cwd=tmp_path,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "[ERROR] missing file: .github/workflows/tests.yml" in result.stdout


def test_policy_check_fails_when_harness_job_is_missing(tmp_path: Path):
    setup_policy_repo(
        tmp_path,
        "name: tests\non:\n  push:\n  pull_request:\njobs:\n  tests:\n    runs-on: ubuntu-latest\n  secret-scan:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/secret-check.sh --patterns-only\n  agents-policy:\n    runs-on: ubuntu-latest\n",
    )

    result = subprocess.run(
        ["bash", "scripts/policy-check.sh"],
        cwd=tmp_path,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "workflow has harness job" in result.stdout


def test_policy_check_fails_when_pr_template_lacks_required_section(tmp_path: Path):
    setup_policy_repo(
        tmp_path,
        "name: tests\non:\n  push:\n  pull_request:\njobs:\n  tests:\n    runs-on: ubuntu-latest\n  secret-scan:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/secret-check.sh --patterns-only\n  harness:\n    runs-on: ubuntu-latest\n    steps:\n      - run: bash scripts/harness.sh\n  agents-policy:\n    runs-on: ubuntu-latest\n",
    )
    write_file(
        tmp_path / "docs" / "pr-template.md",
        "## 目的\n- test\n\n## 主な変更点\n- test\n",
    )

    result = subprocess.run(
        ["bash", "scripts/policy-check.sh"],
        cwd=tmp_path,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "pr template has 検証結果 section" in result.stdout


def test_check_agents_md_script_passes_with_required_content(tmp_path: Path):
    script = Path(__file__).resolve().parents[1] / "toolbox" / "skills" / "bootstrap-repository" / "scripts" / "check-agents-md.sh"
    target = tmp_path / "AGENTS.md"
    target.write_text(
        "# AGENTS\n目的\n優先\n応答\n実行\nGit\nログ\n命名\nkebab-case\nDone条件\n検証結果\n"
        "破壊的操作（git reset --hard）は明示依頼時のみ\nPR本文を正本とする\n"
        "変更可能範囲\n報告フォーマット\n",
        encoding="utf-8",
    )

    result = subprocess.run(
        ["bash", str(script), str(target)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0
    assert "[OK] AGENTS.md check passed" in result.stdout
    assert "[SUMMARY] ERROR: 0, WARN: 0" in result.stdout


def test_check_agents_md_script_fails_when_ambiguous_phrase_exists(tmp_path: Path):
    script = Path(__file__).resolve().parents[1] / "toolbox" / "skills" / "bootstrap-repository" / "scripts" / "check-agents-md.sh"
    target = tmp_path / "AGENTS.md"
    target.write_text(
        "# AGENTS\n目的\n優先\n応答\n実行\nGit\nログ\n命名\nkebab-case\n必要に応じて判断する\n",
        encoding="utf-8",
    )

    result = subprocess.run(
        ["bash", str(script), str(target)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "ambiguous phrase found: 必要に応じて" in result.stdout


def test_check_agents_md_script_warns_when_recommended_sections_missing(tmp_path: Path):
    script = Path(__file__).resolve().parents[1] / "toolbox" / "skills" / "bootstrap-repository" / "scripts" / "check-agents-md.sh"
    target = tmp_path / "AGENTS.md"
    target.write_text(
        "# AGENTS\n目的\n優先\n応答\n実行\nGit\nログ\n命名\nkebab-case\nDone条件\n検証結果\n"
        "破壊的操作（git reset --hard）は明示依頼時のみ\n",
        encoding="utf-8",
    )

    result = subprocess.run(
        ["bash", str(script), str(target)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0
    assert "[WARN]" in result.stdout
    assert "[SUMMARY] ERROR: 0, WARN:" in result.stdout


def test_check_agents_md_script_fails_when_destructive_constraint_missing(tmp_path: Path):
    script = Path(__file__).resolve().parents[1] / "toolbox" / "skills" / "bootstrap-repository" / "scripts" / "check-agents-md.sh"
    target = tmp_path / "AGENTS.md"
    target.write_text(
        "# AGENTS\n目的\n優先\n応答\n実行\nGit\nログ\n命名\nkebab-case\nDone条件\n検証結果\n",
        encoding="utf-8",
    )

    result = subprocess.run(
        ["bash", str(script), str(target)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "missing destructive operation constraints" in result.stdout


def test_check_skill_script_passes_for_valid_skill(tmp_path: Path):
    script = (
        Path(__file__).resolve().parents[1]
        / "toolbox"
        / "skills"
        / "skill-validation-worker"
        / "scripts"
        / "check-skill.sh"
    )
    skill_dir = tmp_path / "toolbox" / "skills" / "sample-worker"
    (skill_dir / "scripts").mkdir(parents=True, exist_ok=True)
    (skill_dir / "SKILL.md").write_text(
        "---\nname: sample-worker\ndescription: test\n---\n\n# sample-worker\n\n目的: test\n\n## 推奨トリガー\n- test\n\n## 出力\n- test\n",
        encoding="utf-8",
    )
    (skill_dir / "scripts" / "run-check.sh").write_text("#!/usr/bin/env bash\necho ok\n", encoding="utf-8")

    result = subprocess.run(
        ["bash", str(script), str(skill_dir)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0
    assert "[OK] skill validation passed" in result.stdout


def test_check_skill_script_fails_with_snake_case_script_name(tmp_path: Path):
    script = (
        Path(__file__).resolve().parents[1]
        / "toolbox"
        / "skills"
        / "skill-validation-worker"
        / "scripts"
        / "check-skill.sh"
    )
    skill_dir = tmp_path / "toolbox" / "skills" / "sample-worker"
    (skill_dir / "scripts").mkdir(parents=True, exist_ok=True)
    (skill_dir / "SKILL.md").write_text(
        "---\nname: sample-worker\ndescription: test\n---\n\n# sample-worker\n\n目的: test\n\n## 推奨トリガー\n- test\n\n## 出力\n- test\n",
        encoding="utf-8",
    )
    (skill_dir / "scripts" / "bad_name.sh").write_text("#!/usr/bin/env bash\necho bad\n", encoding="utf-8")

    result = subprocess.run(
        ["bash", str(script), str(skill_dir)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "script filename should be kebab-case" in result.stdout


def test_check_skill_script_fails_when_frontmatter_name_mismatches(tmp_path: Path):
    script = (
        Path(__file__).resolve().parents[1]
        / "toolbox"
        / "skills"
        / "skill-validation-worker"
        / "scripts"
        / "check-skill.sh"
    )
    skill_dir = tmp_path / "toolbox" / "skills" / "sample-worker"
    skill_dir.mkdir(parents=True, exist_ok=True)
    (skill_dir / "SKILL.md").write_text(
        "---\nname: another-worker\ndescription: test\n---\n\n# sample-worker\n\n目的: test\n\n## 推奨トリガー\n- test\n\n## 出力\n- test\n",
        encoding="utf-8",
    )

    result = subprocess.run(
        ["bash", str(script), str(skill_dir)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0
    assert "frontmatter name must match directory name" in result.stdout


def test_workflow_scripts_exist_and_executable():
    root = Path(__file__).resolve().parents[1]
    start_script = root / "scripts" / "start-branch.sh"
    finish_script = root / "scripts" / "finish-pr.sh"
    triage_script = root / "toolbox" / "skills" / "ci-failure-triage-worker" / "scripts" / "triage-pr-ci.sh"
    quality_script = root / "toolbox" / "skills" / "pr-quality-gate-worker" / "scripts" / "check-pr-quality.sh"

    assert start_script.exists()
    assert finish_script.exists()
    assert triage_script.exists()
    assert quality_script.exists()
    assert os.access(start_script, os.X_OK)
    assert os.access(finish_script, os.X_OK)
    assert os.access(triage_script, os.X_OK)
    assert os.access(quality_script, os.X_OK)


def test_check_pr_quality_passes_with_valid_body_file(tmp_path: Path):
    script = (
        Path(__file__).resolve().parents[1]
        / "toolbox"
        / "skills"
        / "pr-quality-gate-worker"
        / "scripts"
        / "check-pr-quality.sh"
    )
    body = tmp_path / "body.md"
    body.write_text(
        "## 目的\n- test\n\n## 主な変更点\n- test\n\n## 検証結果\n- 実行コマンド: pytest -q\n- 結果: pass\n",
        encoding="utf-8",
    )

    result = subprocess.run(
        ["bash", str(script), "--body-file", str(body)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0
    assert "[OK] PR quality gate passed" in result.stdout


def test_triage_pr_ci_requires_pr_argument():
    script = (
        Path(__file__).resolve().parents[1]
        / "toolbox"
        / "skills"
        / "ci-failure-triage-worker"
        / "scripts"
        / "triage-pr-ci.sh"
    )
    result = subprocess.run(
        ["bash", str(script)],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 2
    assert "Usage:" in result.stdout

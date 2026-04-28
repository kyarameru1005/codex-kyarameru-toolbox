from __future__ import annotations

import subprocess
from pathlib import Path


def script_path() -> Path:
    return (
        Path(__file__).resolve().parents[1]
        / "toolbox"
        / "skills"
        / "harness-report-writer"
        / "scripts"
        / "write-report.sh"
    )


def create_repo_markers(root: Path) -> None:
    skill_dir = root / "toolbox" / "skills" / "harness-report-writer"
    skill_dir.mkdir(parents=True)
    (root / "AGENTS.md").write_text("# AGENTS\n", encoding="utf-8")
    (root / "README.md").write_text("# kyarameru-tool-box\n", encoding="utf-8")
    (skill_dir / "SKILL.md").write_text("# harness-report-writer\n", encoding="utf-8")


def test_write_report_fails_outside_kyarameru_repo(tmp_path: Path):
    result = subprocess.run(
        ["bash", str(script_path()), "--title", "outside-test"],
        cwd=tmp_path,
        input="結論\n実施\n課題\n次\ncmd\nok\n",
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 1
    assert "must be run inside the kyarameru-tool-box repository" in result.stdout
    assert not (tmp_path / "docs" / "harness-reports").exists()


def test_write_report_creates_report_inside_kyarameru_repo(tmp_path: Path):
    create_repo_markers(tmp_path)
    work_dir = tmp_path / "docs"
    work_dir.mkdir(exist_ok=True)

    result = subprocess.run(
        ["bash", str(script_path()), "--title", "inside-test"],
        cwd=work_dir,
        input="結論\n実施\n課題\n次\ncmd\nok\n",
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0
    reports = sorted((tmp_path / "docs" / "harness-reports").glob("*-inside-test.md"))
    assert len(reports) == 1
    content = reports[0].read_text(encoding="utf-8")
    assert "## 結論\n- 結論" in content
    assert "## 検証\n- 実行コマンド: cmd\n- 結果: ok" in content

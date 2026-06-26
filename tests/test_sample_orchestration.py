from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SAMPLE_ROOT = REPO_ROOT / "sample" / "full-agent-demo"


def test_sample_full_agent_demo_exists():
    expected_files = [
        "README.md",
        "01-odin-plan.md",
        "02-heimdall-investigation.md",
        "03-mimir-design.md",
        "04-thor-implementation.md",
        "05-tyr-verification.md",
        "06-forseti-review.md",
        "07-bragi-change-summary.md",
        "task_board.py",
        "test_task_board.py",
    ]

    for relpath in expected_files:
        assert (SAMPLE_ROOT / relpath).exists()


def test_sample_readme_references_all_agents():
    text = (SAMPLE_ROOT / "README.md").read_text()
    for role_name in ["Odin", "Heimdall", "Mimir", "Thor", "Tyr", "Forseti", "Bragi"]:
        assert role_name in text

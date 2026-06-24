from pathlib import Path
import json


REPO_ROOT = Path(__file__).resolve().parents[1]
PLUGIN_MANIFEST = REPO_ROOT / "plugins" / "kyarameru-tool-box" / ".codex-plugin" / "plugin.json"
PLUGIN_ROOT = REPO_ROOT / "plugins" / "kyarameru-tool-box"


def test_plugin_manifest_exists_and_is_minimal():
    manifest = json.loads(PLUGIN_MANIFEST.read_text())

    assert manifest["name"] == "kyarameru-tool-box"
    assert manifest["version"] == "1.0.0"
    assert manifest["interface"]["displayName"] == "Kyarameru Tool Box"
    assert manifest["skills"] == "./skills/"


def test_core_agents_and_skills_exist():
    expected_files = [
        "agents/odin.toml",
        "agents/heimdall.toml",
        "agents/mimir.toml",
        "agents/thor.toml",
        "agents/forseti.toml",
        "agents/tyr.toml",
        "skills/odin/SKILL.md",
        "skills/heimdall/SKILL.md",
        "skills/mimir/SKILL.md",
        "skills/thor/SKILL.md",
        "skills/forseti/SKILL.md",
        "skills/tyr/SKILL.md",
    ]

    for relpath in expected_files:
        assert (PLUGIN_ROOT / relpath).exists()


def test_no_old_role_names_remain_in_plugin():
    old_names = [
        "director",
        "scout",
        "architect",
        "builder",
        "reviewer",
        "verifier",
        "orchestrate",
        "watch",
        "design",
        "forge",
        "judge",
        "verify",
    ]

    texts = []
    for path in PLUGIN_ROOT.rglob("*"):
        if path.is_file():
            texts.append(path.read_text())

    haystack = "\n".join(texts)
    for old_name in old_names:
        assert old_name not in haystack

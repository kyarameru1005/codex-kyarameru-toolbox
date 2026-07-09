from pathlib import Path
import json


REPO_ROOT = Path(__file__).resolve().parents[1]
PLUGIN_MANIFEST = REPO_ROOT / "plugins" / "norse-toolbox" / ".codex-plugin" / "plugin.json"
PLUGIN_ROOT = REPO_ROOT / "plugins" / "norse-toolbox"
MARKETPLACE_FILE = REPO_ROOT / ".agents" / "plugins" / "marketplace.json"
ROLE_NAMES = ["Odin", "Heimdall", "Mimir", "Thor", "Forseti", "Tyr", "Bragi"]


def test_plugin_manifest_matches_norse_toolbox():
    manifest = json.loads(PLUGIN_MANIFEST.read_text())

    assert manifest["name"] == "norse-toolbox"
    assert manifest["version"] == "1.0.0"
    assert manifest["homepage"] == "https://github.com/kyarameru1005/kyarameru-tool-box"
    assert manifest["repository"] == "https://github.com/kyarameru1005/kyarameru-tool-box"
    assert manifest["skills"] == "./skills/"
    assert manifest["interface"]["displayName"] == "Norse Toolbox"
    assert manifest["interface"]["capabilities"] == ["Interactive", "Write"]
    assert len(manifest["interface"]["defaultPrompt"]) == 3


def test_repo_marketplace_contains_norse_toolbox():
    marketplace = json.loads(MARKETPLACE_FILE.read_text())

    assert marketplace["name"] == "kyarameru-codex"
    assert marketplace["interface"]["displayName"] == "Kyarameru Codex"
    assert marketplace["plugins"] == [
        {
            "name": "norse-toolbox",
            "source": {
                "source": "local",
                "path": "./plugins/norse-toolbox",
            },
            "policy": {
                "installation": "AVAILABLE",
                "authentication": "ON_INSTALL",
            },
            "category": "Productivity",
        }
    ]
    assert not (REPO_ROOT / "marketplace.json").exists()


def test_plugin_docs_and_all_skills_exist():
    expected_files = [
        "AGENTS.md",
        "README.md",
        "config.toml",
        ".codex-plugin/plugin.json",
        "agents/README.md",
        "agents/heimdall.toml",
        "agents/odin.toml",
        "agents/mimir.toml",
        "agents/thor.toml",
        "agents/forseti.toml",
        "agents/tyr.toml",
        "agents/bragi.toml",
        "skills/README.md",
        "hooks/.gitkeep",
        "mcp/.gitkeep",
        "memories/.gitkeep",
        "prompts/.gitkeep",
        "skills/odin/SKILL.md",
        "skills/heimdall/SKILL.md",
        "skills/mimir/SKILL.md",
        "skills/thor/SKILL.md",
        "skills/forseti/SKILL.md",
        "skills/tyr/SKILL.md",
        "skills/bragi/SKILL.md",
    ]

    for relpath in expected_files:
        assert (PLUGIN_ROOT / relpath).exists()


def test_readmes_and_agents_doc_reference_reserved_roles():
    checked_files = [
        PLUGIN_ROOT / "README.md",
        PLUGIN_ROOT / "AGENTS.md",
        PLUGIN_ROOT / "agents" / "README.md",
        PLUGIN_ROOT / "skills" / "README.md",
    ]

    for path in checked_files:
        text = path.read_text()
        for role_name in ROLE_NAMES:
            assert role_name in text, f"{role_name} missing from {path}"


def test_all_reserved_skills_are_implemented():
    skill_files = sorted(path.relative_to(PLUGIN_ROOT).as_posix() for path in (PLUGIN_ROOT / "skills").glob("*/SKILL.md"))
    assert skill_files == [
        "skills/bragi/SKILL.md",
        "skills/forseti/SKILL.md",
        "skills/heimdall/SKILL.md",
        "skills/mimir/SKILL.md",
        "skills/odin/SKILL.md",
        "skills/thor/SKILL.md",
        "skills/tyr/SKILL.md",
    ]


def test_all_reserved_agents_are_implemented():
    agent_files = sorted(path.relative_to(PLUGIN_ROOT).as_posix() for path in (PLUGIN_ROOT / "agents").glob("*.toml"))
    assert agent_files == [
        "agents/bragi.toml",
        "agents/forseti.toml",
        "agents/heimdall.toml",
        "agents/mimir.toml",
        "agents/odin.toml",
        "agents/thor.toml",
        "agents/tyr.toml",
    ]

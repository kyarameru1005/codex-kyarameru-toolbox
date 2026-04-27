---
name: mcp-worker
description: Delegates MCP-required tasks to a separate worker Claude process and returns JSON results. Use when external service access (GitHub, Slack, databases) is needed, when MCP tools are required, or when the main session has no MCP available.
allowed-tools: Bash
user-invocable: true
---

# MCP Worker

Runs a separate Claude process with MCP tools enabled, returning structured JSON results.

## Quick Start

```bash
bash ~/.claude/skills/mcp-worker/scripts/run_worker.sh \
  "req_$(date +%Y%m%d-%H%M%S)" \
  "<mcp_name>" \
  "<task>"
```

## Arguments

| Arg | Description | Example |
|-----|-------------|---------|
| request_id | Unique identifier | `req_20241231-120000` |
| mcp_names | MCP config names (space-separated) | `github` or `github slack` |
| task | Task for the worker | `Summarize the README` |

## Output Format

```json
{
  "request_id": "req_xxx",
  "status": "success",
  "summary": "Brief summary",
  "answer_markdown": "Detailed answer in Markdown",
  "sources": ["source1", "source2"]
}
```

## Adding MCP Configs

Create `~/.claude/skills/mcp-worker/mcp-configs/<name>.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

## Additional Resources

- [REFERENCE.md](REFERENCE.md) - Detailed API and configuration
- [schema.worker-result.json](schema.worker-result.json) - Output JSON schema

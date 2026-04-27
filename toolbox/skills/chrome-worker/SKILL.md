---
name: chrome-worker
description: Delegates browser-related tasks (UI verification, design checks, web automation) to a separate Claude process with Chrome integration enabled. Requires Chrome browser with Claude extension installed and visible.
allowed-tools: Bash
user-invocable: true
---

# Chrome Worker

Runs a separate Claude process with Chrome integration (`--chrome`) for browser-based tasks.

## Quick Start

```bash
bash ~/.claude/skills/chrome-worker/scripts/run_worker.sh \
  "req_$(date +%Y%m%d-%H%M%S)" \
  "<task>"
```

## Arguments

| Arg | Description | Example |
|-----|-------------|---------|
| request_id | Unique identifier | `req_20241231-120000` |
| task | Browser task to perform | `Check the login form design` |

## Use Cases

- UI/UX verification and design checks
- Visual regression testing
- Form validation testing
- Screenshot capture and comparison
- Console error monitoring
- Authenticated workflow testing (sites you're logged into)

## Requirements

- Google Chrome browser (visible window required)
- Claude in Chrome extension v1.0.36+
- Claude Code v2.0.73+
- Paid Claude plan (Pro, Team, or Enterprise)

## Output Format

```json
{
  "request_id": "req_xxx",
  "status": "success",
  "summary": "Brief summary",
  "answer_markdown": "Detailed findings in Markdown",
  "screenshots": ["path/to/screenshot1.gif"],
  "console_errors": ["error1", "error2"],
  "sources": ["https://example.com"]
}
```

## Limitations

- Chrome window must be visible (no headless mode)
- WSL is not supported
- Only Google Chrome supported (not Brave, Arc, etc.)

## Additional Resources

- [REFERENCE.md](REFERENCE.md) - Detailed API and troubleshooting
- [schema.worker-result.json](schema.worker-result.json) - Output JSON schema

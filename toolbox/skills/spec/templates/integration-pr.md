## Summary

**{{PROJECT_NAME}}** の全 Feature を統合した PR。

### Features included

| # | Feature | Issue | Wave | Status |
|---|---------|-------|------|--------|
{{#each FEATURES}}
| {{@index}} | {{name}} | #{{issue_number}} | {{wave}} | merged |
{{/each}}

### Key changes

<!-- 各 Feature の design.md から主要な変更をサマリ -->

{{#each FEATURES}}
- **{{name}}**: {{summary}}
{{/each}}

## Test results

| テスト種別 | 結果 | 詳細 |
|-----------|------|------|
| Unit tests | PASS / FAIL | {{UNIT_RESULT}} |
| Integration tests | PASS / FAIL | {{INTEGRATION_RESULT}} |
| E2E tests | PASS / FAIL / N/A | {{E2E_RESULT}} |
| Lint | PASS / FAIL | {{LINT_RESULT}} |
| 型チェック | PASS / FAIL / N/A | {{TYPE_RESULT}} |

## Audit results

| Wave | 判定 | 詳細 |
|------|------|------|
{{#each WAVES}}
| Wave {{@index}} | {{verdict}} | {{summary}} |
{{/each}}

## Review points

<!-- 重要なレビューポイント -->

- [ ] {{REVIEW_POINT_1}}
- [ ] {{REVIEW_POINT_2}}

---

Generated with [Claude Code](https://claude.com/claude-code) - Multi-Feature Parallel Development

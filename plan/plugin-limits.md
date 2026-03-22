# Claude Code Plugin Quirks

Discovered 2026-03-21.

## Commands silently dropped

`plugin.json` declares 7 commands. Only the first 5 appear in autocomplete:

| # | Command | Visible? |
|---|---------|----------|
| 1 | setup | yes |
| 2 | scan | yes |
| 3 | run | yes |
| 4 | sleep | yes |
| 5 | deploy | yes |
| 6 | help | no |
| 7 | lib:readme | no |

No error, no warning. They just don't show up.

## Skills also affected

2 skills declared, only the first appears:

| # | Skill | Visible? |
|---|-------|----------|
| 1 | complexity-scorer | yes |
| 2 | housekeeping | no |

## No documented limit

Official plugin docs, changelog, and community guides don't mention any cap on commands or skills per plugin. Official examples show plugins with many items.

## Untested

- Do the missing items work if typed manually?
- Does reordering the array change which items appear?
- Is this a Claude Code version-specific bug?

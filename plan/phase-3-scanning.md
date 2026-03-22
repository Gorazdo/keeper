# Phase 3: Scanning & Code Lenses

## Status: ✅ Complete

## Files to Create

- `agents/scanner.md` — unified multi-lens scanner (haiku)
- `commands/scan.md` — quick health report command
- 8 code lens files in `lenses/` (ported from untangle-with-ralph-loop)
- `skills/complexity-scorer/SKILL.md` (ported from untangle)

## Scanner Agent

Model: haiku (fast, deterministic).

Reads active lens files, applies detection rules across the codebase, returns ranked findings.

Input: source globs, exclude globs, active lenses, completed/skip lists.
Output: structured ranked findings table with lens, severity, location, description.

## Scan Command

Read-only health report. Spawns scanner with all active lenses, displays summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper v1.2.0 | scan | 5 lenses active
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 docs-coverage: 78% · 2 drift issues
🏷️ labelling: 62% · 38 unlabeled files
🔧 untangling: 3 functions > threshold
⚠️ error-handling: 5 swallowed errors
🧪 testability: 12 untested exports

Top 3 priorities:
1. error-handling: 5 swallowed errors in src/api/
2. untangling: processOrder CC:24
3. labelling: 38 unlabeled files

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [R] Run · [D] Details · [X] Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Code Lenses (8, ported from untangle)

Each gets added frontmatter:
```yaml
---
name: Untangling
description: Structural complexity — nesting, boolean chains, too many responsibilities
scope: function
type: code
agent: doer
---
```

| Lens | Source |
|------|--------|
| untangling.md | untangle-with-ralph-loop/lenses/untangling.md |
| modernization.md | untangle-with-ralph-loop/lenses/modernization.md |
| testability.md | untangle-with-ralph-loop/lenses/testability.md |
| boundaries.md | untangle-with-ralph-loop/lenses/boundaries.md |
| micro-hygiene.md | untangle-with-ralph-loop/lenses/micro-hygiene.md |
| type-safety.md | untangle-with-ralph-loop/lenses/type-safety.md |
| friction.md | untangle-with-ralph-loop/lenses/friction.md |
| error-handling.md | untangle-with-ralph-loop/lenses/error-handling.md |

## Complexity Scorer Skill

Ported as-is from untangle-with-ralph-loop/skills/complexity-scorer/SKILL.md.
SonarQube cognitive complexity algorithm fallback.

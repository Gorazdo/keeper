---
name: Housekeeping
description: Enforce canonical _keeper/ directory structure — detect and relocate stray runtime files from project root.
---

# Housekeeping Skill

Defines the canonical `_keeper/` directory structure and remediates stray keeper runtime files found at project root.

## Canonical Structure

```
.keeperrc.json                          # Procedural memory (stays at root)
_keeper/
├── memory.json                         # Short-term memory
├── output/
│   ├── supervised/                     # Interactive session output
│   │   └── YYYY-MM-DD-{type}.{ext}
│   └── autonomous/                     # Daemon/background output
│       └── YYYY-MM-DD-{type}.{ext}
├── encyclopedia/                       # Long-term memory
│   ├── architecture.md
│   ├── patterns.md
│   ├── gotchas.md
│   ├── taxonomy.md
│   └── conventions.md
├── history.md                          # Heritage, moments
├── briefing.md                         # Morning briefing
└── daemon.sh                           # Generated daemon script
```

**Output naming:** `YYYY-MM-DD-{type}.{ext}` — e.g. `2026-03-19-scan-detailed.md`, `2026-03-19-scan-summary.md`, `2026-03-19-scan-results.txt`

## Stray File Patterns

Detect these patterns at project root (NOT inside `_keeper/`):

| Pattern | Correct location |
|---------|-----------------|
| `.keeper-memory.json` | `_keeper/memory.json` |
| `keeper-daemon.sh` | `_keeper/daemon.sh` |
| `KEEPER_SCAN*` | `_keeper/output/{mode}/YYYY-MM-DD-scan-*` |
| `keeper-*.md` | Inspect and relocate to `_keeper/output/` |

**Never flag:** `.keeperrc.json` — this is a conventional dotfile that stays at root.

## Remediation

For each stray file found:

1. **Determine destination** — match against the table above
2. **Date prefix** — if the file lacks a date prefix, use the file's mtime or today's date
3. **Mode** — if invocation context is unknown, default to `supervised/`
4. **Move** — relocate file to correct `_keeper/` location
5. **Log** — report what was moved and where

## Validation

After remediation, verify `_keeper/` has the required structure:

- [ ] `_keeper/memory.json` exists
- [ ] `_keeper/output/supervised/` directory exists
- [ ] `_keeper/output/autonomous/` directory exists
- [ ] `_keeper/encyclopedia/` directory exists with at least `architecture.md`
- [ ] `_keeper/history.md` exists
- [ ] `_keeper/briefing.md` exists

Create any missing directories. Do NOT create missing files (those are created by setup).

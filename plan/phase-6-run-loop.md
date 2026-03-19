# Phase 6: Run Loop & PRs

## Status: ⬜ Pending

## Files to Create

- `commands/run.md` — autonomous work loop

## Run Loop

The main command, designed for `/loop` integration.

### Steps

1. **SCAN** — spawn scanner (haiku) with active lenses from config
2. **PRIORITIZE** — rank findings by severity across all lenses:
   - Critical: broken tests, swallowed errors on I/O
   - High: complex functions (CC > 2× threshold), docs drift
   - Medium: unlabeled files, moderate complexity, missing JSDoc
   - Low: micro-hygiene suggestions, markdown formatting
3. **SELECT LENS** — pick the highest-impact lens with pending work
4. **CALIBRATE** — if first time for this lens, run progressive calibration
5. **WORK** — dispatch to lens's agent for 3-5 targets:
   - Code lenses → doer agent (one function at a time, full loop)
   - Labelling → tagger agent (batch of ~20 files)
   - Other doc lenses → doer agent
6. **PR** — create PR for completed batch:
   - One lens per PR
   - Branch: `keeper/{lens}-{YYYY-MM-DD-HHmm}`
   - Title: `{type}({lens}): {short description}`
   - Body: lens, files changed, before/after metrics
7. **REMEMBER** — update short-term memory:
   - Add to `pendingConsolidation`
   - Update `completedFunctions` / `taggedFiles`
   - Record techniques that worked/failed
8. **CHECK SCHEDULE** — if sleeping hours → trigger sleep → pause
9. **REPEAT** — back to SCAN (codebase changed, re-scan)

### Interaction by Context

| Context | Steps with interaction |
|---------|----------------------|
| Direct (supervised) | AskUserQuestion at steps 3, 5, 6 |
| Via `/loop` | Same as supervised, between cycles |
| Via tmux (autonomous) | No stops — auto-select, auto-work, auto-PR |

### Exit Conditions

- No targets found across any active lens → report success
- Max iterations reached (from config) → report and stop
- Sleeping hours reached (tmux mode) → sleep → pause
- User says done (supervised) → stop

### PR Strategy — "Midnight Snacks"

- One lens per PR, 3-5 functions/files
- Title: `refactor(untangling): extract guard clauses in 4 API handlers`
- Body: lens description, files changed, complexity before→after, tests added
- Tests included in same PR
- No mixed concerns

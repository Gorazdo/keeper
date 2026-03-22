---
name: sleep
description: Memory consolidation — promote proven patterns to encyclopedia, prune short-term memory, enforce directory structure, generate morning briefing. Runs during sleeping hours or on demand.
user-invokable: true
disable-model-invocation: true
---

# Keeper Sleep — Memory Consolidation

Arguments: $ARGUMENTS (supports `--dry-run`)

You are the night-shift keeper. While the codebase rests, you consolidate what was learned into long-term memory, enforce directory hygiene, and prepare the morning briefing.

Follow the personality and output format from `personality.md`.

---

## Step 0: Pre-flight

### 0a. Load config and memory

Read `.keeperrc.json` and `_keeper/memory.json`. If either is missing:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | sleep | ⚠️ Not set up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /keeper:setup first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

### 0b. Create lock file

```bash
date -u "+%Y-%m-%dT%H:%M:%SZ" > _keeper/.lock
```

The timestamp lets hooks detect stale locks (>60 min) from crashed sessions.

### 0c. Check pending work

Read `sessions.pendingConsolidation` from memory. If empty:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | sleep | 🌙 Nothing to consolidate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No pending learnings. Memory is up to date.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
Skip to Step 6.5 (Housekeep) — still run housekeeping even with nothing to consolidate.

### 0d. Parse arguments

- `--dry-run` → show what would be consolidated, don't write anything

### 0e. Initialize

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v{version} | sleep | 🌙 Consolidating
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{N} pending entries to process.

▓░░░░░░░░░░░░░░░░░░░░░░░░ 0% · Starting consolidation...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 1: TRIAGE

Review every entry in `pendingConsolidation`. For each entry, classify:

### Promote (→ encyclopedia)
- Refactoring pattern used successfully ≥2 times
- Gotcha encountered ≥2 times
- Category pattern with ≥3 correct matches
- Architecture insight confirmed by multiple sessions
- Coding convention observed consistently

### Keep (stays in short-term)
- Pattern used once, successful — needs more data
- Recent gotcha (seen once, less than 3 sessions old)
- Unproven category guess

### Discard
- Pattern that failed more than it succeeded
- Gotcha proven irrelevant (function was refactored away)
- Stale entry (>10 sessions old, never confirmed)
- Duplicate of already-promoted knowledge

Output per entry:
```
  ↗️ PROMOTE: Guard clause extraction (8/9 success rate)
  ➡️ KEEP: Early return for validation (1/1, needs more data)
  🗑️ DISCARD: Inline temp variable (0/3, not effective)
```

```
▓▓▓▓▓░░░░░░░░░░░░░░░░░░░ 17% · Triage complete
```

---

## Step 2: CONSOLIDATE

For each entry classified as PROMOTE, write to the appropriate encyclopedia article in `_keeper/encyclopedia/`.

### Target articles

| Source type | Target file |
|------------|-------------|
| Refactoring pattern | `patterns.md` |
| Gotcha | `gotchas.md` |
| Category pattern | `taxonomy.md` |
| Architecture insight | `architecture.md` |
| Coding convention | `conventions.md` |

### Article entry format

For `patterns.md`:
```markdown
## {Pattern Name}
- **Success rate**: {n}/{total} ({percent}%)
- **Best for**: {contexts where this works well}
- **Average impact**: {e.g., "CC reduction: 6 points" or "coverage +15%"}
- **Technique**: {brief description of the approach}
- **First seen**: {date}
- **Last used**: {date}
```

For `gotchas.md`:
```markdown
## {Gotcha Title}
- **Frequency**: Seen {n} times
- **Context**: {when this gotcha appears}
- **Mitigation**: {how to handle it}
- **First seen**: {date}
```

For `taxonomy.md`:
```markdown
## {Category} → {Pattern}
- **Rule**: Files matching `{glob or naming pattern}` → category `{category}`
- **Confidence**: {n}/{total} correct
- **Examples**: {2-3 file paths}
```

For `architecture.md`:
```markdown
## {Insight}
- **Observation**: {what was noticed}
- **Impact on work**: {how this affects refactoring/labelling/docs decisions}
- **Confirmed**: {n} sessions
```

For `conventions.md`:
```markdown
## {Convention}
- **Pattern**: {description}
- **Scope**: {where it applies — e.g., "test files", "API handlers"}
- **Confirmed**: {n} sessions
```

### Writing rules

- If an article doesn't exist yet → create it with a top-level heading and the first entry
- If an entry for the same pattern/gotcha already exists → **update** it (increment counts, update dates, merge contexts)
- Never duplicate entries — match by name/topic
- Keep articles sorted: most-used entries first

```
▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░ 33% · Consolidated {N} entries
```

---

## Step 3: PRUNE

Clean short-term memory (`_keeper/memory.json`):

### Remove
- All promoted entries (now in encyclopedia)
- All discarded entries

### Cap limits
- `refactoring.patterns`: max 50 (remove oldest with lowest success rate)
- `refactoring.gotchas`: max 25 (remove oldest)
- `refactoring.patternRegistry`: max 20 (remove least-used)
- `tags.taggedFiles`: remove entries for files that no longer exist on disk
- `sessions.pendingConsolidation`: clear entirely

### Verify tagged files
For each entry in `tags.taggedFiles`, check if the file still exists. Remove dead entries.

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░ 50% · Pruned {N} entries, {M} dead refs
```

---

## Step 4: INTEGRATE

Cross-reference newly promoted entries with existing encyclopedia content.

### Cross-reference
- If a new pattern relates to an existing gotcha → add "See also" link in both
- If a new gotcha affects a documented architecture pattern → note it
- If taxonomy and conventions overlap → reconcile

### Detect conflicts
- If a new entry contradicts an existing one → flag for review, keep both with a `⚠️ Conflict` marker
- Example: pattern says "always extract guard clauses" but gotcha says "guard clauses break in recursive functions" → note the exception in the pattern entry

### Update architecture
If session results revealed new module boundaries, key exports, or dependency patterns → update `architecture.md`.

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░ 67% · Integrated cross-references
```

---

## Step 5: PLAN

Queue prioritized targets for the next session.

### Gather inputs
1. **Scanner findings** — if a recent scan exists in memory, use its rankings
2. **Memory insights** — patterns that worked well suggest similar targets
3. **Incomplete work** — functions that stalled, files partially labelled
4. **Human review queue** — items flagged for human review (deprioritize, but list)

### Prioritize
Rank by:
1. **Severity** — critical findings first (broken tests, swallowed errors)
2. **Momentum** — targets similar to recent successes (proven patterns apply)
3. **Quick wins** — high isolatability, moderate complexity
4. **Blocked** — items needing human review go to end

### Queue format
```json
{
  "plannedTargets": [
    {
      "lens": "untangling",
      "target": "processOrder",
      "file": "src/api/orders.ts",
      "reason": "CC:24, guard clause extraction likely effective",
      "priority": 1
    }
  ]
}
```

Write queue to `sessions.plannedTargets` in `_keeper/memory.json`.

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 83% · Planned {N} targets
```

---

## Step 6: BRIEF

Write the morning briefing to `_keeper/briefing.md`.

### Briefing format

```markdown
# Morning Briefing — {YYYY-MM-DD}

## Yesterday
- {What was accomplished — lens by lens}
- {PRs created, status}
- {Functions untangled, files labelled, docs fixed}

## Learned
- {Patterns promoted to encyclopedia}
- {New gotchas discovered}
- {Category patterns confirmed}

## Today's Plan
1. {Top priority target — lens, function/file, reason}
2. {Second priority}
3. {Third priority}
...up to 10 targets

## Needs Attention
- {Items flagged for human review, if any}
- {Conflicts detected during integration, if any}
```

### Update session metadata

In `_keeper/memory.json`:
```json
{
  "sessions": {
    "lastSleep": "{ISO timestamp}",
    "pendingConsolidation": []
  }
}
```

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 88% · Briefing written
```

---

## Step 6.5: HOUSEKEEP

Enforce the canonical `_keeper/` directory structure.

### Canonical structure

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
└── briefing.md                         # Morning briefing
```

**Output naming:** `YYYY-MM-DD-{type}.{ext}` — e.g. `2026-03-19-scan-detailed.md`

### Detect and relocate stray files

Glob project root for stray keeper files:

| Pattern | Correct location |
|---------|-----------------|
| `.keeper-memory.json` | `_keeper/memory.json` |
| `keeper-daemon.sh` | delete (no longer generated) |
| `KEEPER_SCAN*` | `_keeper/output/{mode}/YYYY-MM-DD-scan-*` |
| `keeper-*.md` | Inspect and relocate to `_keeper/output/` |

**Never flag:** `.keeperrc.json` — this is a conventional dotfile that stays at root.

For each stray file found:
1. Determine destination from the table above
2. Add date prefix if missing (use file mtime or today's date)
3. Default to `supervised/` if invocation context is unknown
4. Move file to correct location
5. Log what was moved

### Validate structure

Verify `_keeper/` has required subdirectories and create any missing:
- `_keeper/output/supervised/`
- `_keeper/output/autonomous/`
- `_keeper/encyclopedia/`

Do NOT create missing files (those are created by setup).

### Report

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 92% · Housekeeping complete
```

---

## Step 7: Report

Remove lock file: `rm -f _keeper/.lock`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | sleep | 🌙 Consolidation Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Triage: {N} promoted · {M} kept · {K} discarded

Encyclopedia updated:
  {article}: +{N} entries
  {article}: {N} entries updated

🧹 Pruned: {N} stale entries, {M} dead file refs
🧹 Housekeeping: {N} stray files moved (or "clean")

📋 Tomorrow: {N} targets planned
  1. {top target}
  2. {second target}
  3. {third target}

{If conflicts detected:}
⚠️ {N} conflict(s) need review in encyclopedia

Briefing: _keeper/briefing.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

1. **Never discard data without checking.** Verify file existence before pruning tagged files. Verify pattern conflicts before overwriting.
2. **Update, don't duplicate.** If an encyclopedia entry already covers a topic, update it — don't create a second entry.
3. **Preserve history.** When updating encyclopedia entries, keep the "First seen" date intact.
4. **Dry-run is read-only.** With `--dry-run`, show classification and plans but write nothing.
5. **Bounded memory.** Respect cap limits. Short-term memory must stay lean.
6. **Honest briefing.** Report what actually happened, not what was planned. Include failures and stalls.
7. **Idempotent.** Running sleep twice in a row with no new work should be a no-op (empty pending → skip to housekeep).
8. **Always housekeep.** Even if there's nothing to consolidate, still run Step 6.5.
9. **Lock file discipline.** Create `_keeper/.lock` at start, remove at end.

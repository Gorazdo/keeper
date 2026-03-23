# Phase 7: Sleep & Encyclopedia

## Status: ✅ Complete

## Files to Create

- `commands/sleep.md` — consolidation command

## Sleep Consolidation

Brain-inspired memory consolidation. Runs during sleeping hours (automatic in tmux mode) or on demand via `/keeper-sleep`.

### 6-Step Cycle

1. **TRIAGE** — review `pendingConsolidation` in short-term memory
   - Score each entry: pattern frequency, success rate, complexity reduction
   - Classify: **promote** (≥2 successes), **keep** (1 success, recent), **discard** (failed, stale)

2. **CONSOLIDATE** — move proven knowledge to encyclopedia
   - Refactoring patterns with ≥2 successes → `_keeper/encyclopedia/patterns.md`
   - Gotchas encountered ≥2 times → `_keeper/encyclopedia/gotchas.md`
   - Category patterns with high confidence → `_keeper/encyclopedia/taxonomy.md`
   - Detected conventions → `_keeper/encyclopedia/conventions.md`
   - Architecture insights → `_keeper/encyclopedia/architecture.md`

3. **PRUNE** — clean short-term memory
   - Remove promoted entries
   - Remove discarded entries
   - Cap: patterns at 50, gotchas at 25, patternRegistry at 20
   - Clear `pendingConsolidation`

4. **INTEGRATE** — connect new with existing
   - Cross-reference new patterns with existing encyclopedia entries
   - Update existing entries rather than duplicate
   - Add "See also" links between related entries

5. **PLAN** — queue targets for next session
   - Based on: scanner findings + memory insights + what worked well
   - Write prioritized target list to briefing

6. **BRIEF** — write `_keeper/briefing.md`
   ```markdown
   # Morning Briefing — {date}

   ## Yesterday
   - Untangled 4 functions (guard clause extraction)
   - Labelled 23 files (Hook, Component categories)
   - Created 2 PRs, both pending review

   ## Learned
   - Guard clause extraction works well for API handlers
   - Files in /hooks/ are reliably Hook category (promoted)

   ## Today's Plan
   1. Untangle: processOrder (CC:24) — try decompose
   2. Label: 15 remaining files in src/utils/
   3. Error handling: 5 swallowed errors in src/api/
   ```

### Automatic Trigger (tmux mode)

In `/keeper-run` via tmux:
1. After each work cycle, check current time against `schedule.workingHours`
2. If outside working hours → run sleep consolidation → pause
3. On next working hour → load briefing → resume with planned targets

### Encyclopedia Structure

Each article is a growing markdown file with sections that get appended/updated:

```markdown
# Patterns

## Guard Clause Extraction
- **Success rate**: 8/9 (89%)
- **Best for**: API handlers with deep nesting, validation-heavy functions
- **Average CC reduction**: 6 points
- **First seen**: 2026-03-19
- **Last used**: 2026-03-25

## Decompose Long Function
- **Success rate**: 3/5 (60%)
...
```

# Phase 4: Code Lens Execution

## Status: ✅ Complete

## Files to Create

- `agents/doer.md` — refactoring agent (sonnet, opus escalation)

## Doer Agent

Ported from untangle-with-ralph-loop/agents/doer.md with lens-aware adaptations.

Model: sonnet (standard), opus (escalation).

Works on ONE function continuously until targets met or stalled:
1. **ANALYZE** — deep read, determine strategy, check memory for gotchas
2. **COVER** — write tests (temporal if untestable → isolate → promote)
3. **UNTANGLE** — refactor one move at a time, lens-guided
4. **VERIFY** — backpressure gates after each move

### Backpressure Gates
- All tests MUST pass
- Coverage MUST NOT decrease
- Complexity MUST NOT increase (hold OK if coverage improved)
- Function signature MUST NOT change
- Zero `// TEMPORAL` markers at exit

### Escalation
- Sonnet stalls (3 iterations, no metric improved) → re-spawn with opus + stall context
- Opus stalls → mark for human review

### Progressive Calibration (untangling lens)
On first use of any code lens via `/keeper-run`:
1. Choose active code lenses (AskUserQuestion multi-select)
2. Present 7 refactoring proposals as diffs (scanner finds candidates, doer proposes)
3. User rates: Approve / Reject / Different strategy / Comment
4. Iterate until 5/7 approved
5. Save style preferences to `.keeper-memory.json`

### Lens-Aware Behavior
- Doer reads the active lens file to understand what class of problem to address
- Prefers techniques from memory that succeeded on similar lens findings
- Avoids techniques that failed on similar patterns
- Reports which lens finding was addressed per refactoring move

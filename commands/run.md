---
description: Autonomous work loop — scan across lenses, pick highest-priority targets, dispatch to agents, create focused PRs. Designed for /loop and tmux integration.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# Keeper Run — Autonomous Loop

Arguments: $ARGUMENTS (supports `--dry-run`, `--max-iterations N`, `--lens <name>`)

You are the orchestrator for the keeper plugin. You run the outer loop: scan through active lenses, pick the highest-priority work, dispatch to the right agent, handle results, create PRs, update memory, and loop until done or sleeping hours.

Follow the personality and output format from `agents/personality.md`.

---

## Step 0: Pre-flight

### 0a. Load config

Read `.keeperrc.json` at project root. If missing:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | run | ⚠️ Not set up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /keeper:setup first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

### 0b. Load memory

Read `.keeper-memory.json`. Create empty if missing.

Load `_keeper/briefing.md` if it exists — use planned targets as initial priority hints.

### 0c. Parse arguments

- `--dry-run` → scan and show targets only, no changes
- `--max-iterations N` → override config
- `--lens <name>` → restrict to a single lens (skip others)

### 0d. Determine invocation context

Check if running interactively (Claude Code) or autonomously (tmux/bash):
- If `AskUserQuestion` is available and user is present → **supervised mode**
- If running via `/loop` → **repeating mode** (supervised between cycles)
- If neither → **autonomous mode** (no user interaction)

### 0e. Git strategy (supervised mode only)

Use AskUserQuestion ONCE:
- "Branch strategy for this session?"
  - **Create branch** — `keeper/session-{YYYY-MM-DD-HHmm}`
  - **Current branch** — work on whatever's checked out
  - **Skip** — I'll handle git myself

In autonomous mode: always create branch `keeper/session-{YYYY-MM-DD-HHmm}`.

### 0f. Progressive calibration check

For each active lens, check if calibration is needed:
- **labelling**: if `calibration.labelling.calibratedOn` is null → run labelling calibration (see `lenses/labelling.md` "Progressive calibration" section)
- **untangling** (or any code lens): if `calibration.untangling.calibratedOn` is null → run untangling calibration (present 7 refactoring proposals, learn style)

In autonomous mode: skip calibration, use defaults.

### 0g. Validate test runner (if code lenses active)

Run test command once to confirm it works. If fails: warn and disable code lenses for this session.

### 0h. Initialize session

```
outerIteration = 0
sessionResults = []
maxIterations = from args or config (default: 15)
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.0.0 | run | ⚙️ Session started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{projectName} · {N} lenses active
Thresholds: CC ≤ {T}, coverage ≥ {T}%
Max iterations: {N}
Branch: {branch}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 1: SCAN

Spawn the scanner agent:
- `subagent_type`: `keeper:scanner`
- `description`: `Scan codebase (iteration {N})`
- Provide: source/exclude globs, threshold, active lenses, scan mode (`full` or filtered by `--lens`), completed functions, tagged files, human review list

Wait for results. Parse structured output.

**If `--dry-run`:** Display targets and STOP.
**If no targets found:** Go to Step 7 (Final Report — all clear).

---

## Step 2: PRIORITIZE

Rank all findings by severity across all lenses:

| Priority | Criteria |
|----------|----------|
| Critical | Broken tests, swallowed errors on I/O, docs drift on exported APIs |
| High | Complex functions (CC > 2× threshold), warning-level findings |
| Medium | Moderate complexity, unlabeled files, missing JSDoc on public API |
| Low | Suggestions, micro-hygiene, markdown formatting |

---

## Step 3: SELECT LENS

Pick the highest-impact lens with pending work.

In supervised mode: Use AskUserQuestion:
- "Top priority is {lens}: {description}. Start here?"
  - **Yes** — proceed with this lens
  - **Pick different** — show all lenses with pending work, let user choose
  - **Dry run** — show what would be done, don't act

In autonomous mode: auto-select top priority lens.

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | run | ⚙️ {lens} · iteration {N}/{max}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 4: WORK

Dispatch to the lens's agent for a batch of targets (3-5 from the same lens).

### For code lenses (agent: doer)

For each target function, ONE AT A TIME:

Build the doer prompt with full context:
- Target function (name, file, lines, complexity, problem types)
- **Active lens name** — which lens flagged this function
- Thresholds, test config
- Style preferences from memory
- Relevant techniques (worked/failed) from memory
- Relevant gotchas from memory
- Model context (first attempt on sonnet, or escalation context)

Spawn doer agent:
- `subagent_type`: `keeper:doer`
- `description`: `{lens}: {functionName}`

Process doer result:

**SUCCESS:**
```
✅ {functionName} — CC: {before}→{after}, cov: {before}%→{after}%
```
Add to completed.

**STALLED (sonnet, ESCALATION_NEEDED):**
Re-spawn with opus + stall context. If opus also stalls → mark for human review.

**HARD_LIMIT:**
Record as partial.

After completing or stalling on 3-5 functions from this lens → go to Step 5.

### For labelling lens (agent: tagger)

Group unlabeled files into batches of ~20.

Spawn tagger agent:
- `subagent_type`: `keeper:tagger`
- `description`: `Label batch ({N} files)`
- Provide: file paths, categories, header format, comment syntax, learned patterns, custom rules

Parse tagger output. For each file:
- Read current content
- Check for existing header, replace if found
- If new: prepend header + blank line
- Use Edit to apply

After applying headers for a batch → go to Step 5.

### For other doc lenses (agent: doer)

Spawn doer with the doc lens context. The doer handles JSDoc, markdown, and docs-coverage fixes the same way it handles code — one target at a time with verification.

---

## Step 5: PR

Create a PR for the completed batch. One lens per PR.

### Branch

If not already on a feature branch:
```bash
git checkout -b keeper/{lens}-{YYYY-MM-DD-HHmm}
```

### Commit (if not already committed by doer)

For labelling batches:
```bash
git add [modified files]
git commit -m "docs(labelling): label {N} files as {categories}

Lens: labelling
Files: {N} labelled"
```

### PR creation

In supervised mode: Use AskUserQuestion:
- "Create PR for this batch?"
  - **Create PR** — proceed
  - **Skip PR** — keep commits, don't create PR
  - **Continue working** — add more to this batch before PR

In autonomous mode: auto-create PR.

```bash
gh pr create --title "{type}({lens}): {short description}" --body "$(cat <<'PREOF'
## Summary
- **Lens**: {lens}
- **Files changed**: {N}
- **Targets addressed**: {list}

## Metrics
{before/after table for each target}

## What was done
{brief description of techniques applied}

🔒 Generated by Keeper
PREOF
)"
```

After PR creation, switch back to main branch for next cycle:
```bash
git checkout {original branch}
```

---

## Step 6: REMEMBER

Update `.keeper-memory.json`:

### 6a. Record results

- Add to `pendingConsolidation` for sleep processing
- Update `completedFunctions` or `taggedFiles`
- Record techniques that worked/failed
- Record gotchas discovered
- Update pattern registry

### 6b. Prune

Keep bounded:
- `refactoring.patterns`: max 50
- `refactoring.gotchas`: max 25
- `refactoring.patternRegistry`: max 20
- `tags.taggedFiles`: no limit (but prune dead entries)

### 6c. Check schedule

If `schedule.workingHours` is configured:
- Get current time in configured timezone
- If outside working hours → go to sleep: run `/keeper:sleep` logic, then PAUSE

---

## Step 7: CHECK EXIT CONDITIONS

### All clear
No targets found across any active lens:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | run | ✅ All clear
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No more targets across {N} active lenses.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
→ Go to Step 8 (Final Report).

### Max iterations
`outerIteration >= maxIterations` → Go to Step 8.

### More work
→ Go back to Step 1 (re-scan — codebase changed).

---

## Step 8: Final Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | run | 📊 Session Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{For each result:}
{✅|⚠️|🛑|⏱️} {target} — {lens} — {before}→{after}

PRs created: {N}
Commits: {total}
Lenses worked: {list}

{If human review needed:}
📋 {N} target(s) need human review

{If promotion candidates:}
🔄 {N} extracted helper(s) — candidates for shared utility

Memory updated: .keeper-memory.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

1. **You are the orchestrator.** Spawn agents, don't refactor code yourself.
2. **Re-scan after each batch.** Codebase changes. Get fresh results.
3. **One lens per PR.** Never mix labelling and refactoring in one PR.
4. **Parse agent reports carefully.** Extract all fields for memory updates.
5. **Escalate honestly.** Sonnet → opus → human review. Don't spin.
6. **Keep memory bounded.** Prune old entries.
7. **Ask git strategy ONCE.** Not per function or lens.
8. **Show progress.** Output iteration headers and results.
9. **Respect schedule.** If sleeping hours → consolidate and pause.
10. **3-5 targets per lens batch.** Small PRs. Midnight snacks.

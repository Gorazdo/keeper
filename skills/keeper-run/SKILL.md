---
name: keeper-run
description: ▶️ Autonomous work loop — scan across lenses, pick highest-priority targets, dispatch to agents in worktrees, push branches. Designed for /loop and tmux integration.
user-invokable: true
disable-model-invocation: false
---

# Keeper Run — Autonomous Loop

Arguments: $ARGUMENTS (supports `--dry-run`, `--max-iterations N`, `--lens <name>`, `--workflow <name>`)

You are the orchestrator for the keeper plugin. You run the outer loop: scan through active lenses, pick the highest-priority work, dispatch to the right agent (in worktree isolation), handle results, push branches, update memory, and loop until done or sleeping hours.

Follow the personality and output format from `personality.md`.

---

## Step 0: Pre-flight

### 0a. Load config

Read `.keeperrc.json` at project root. If missing:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | ⚠️ Not set up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /keeper-setup first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

### 0b. Load memory

Read `_keeper/memory.json`. Create empty if missing.

Load `_keeper/briefing.md` if it exists — use planned targets as initial priority hints.

### 0c. Create lock file

```bash
date -u "+%Y-%m-%dT%H:%M:%SZ" > _keeper/.lock
```

This prevents nudge hooks from firing during the run session. The timestamp lets hooks detect stale locks (>60 min) from crashed sessions.

### 0d. Parse arguments

- `--dry-run` → scan and show targets only, no changes
- `--max-iterations N` → override config
- `--lens <name>` → restrict to a single lens (skip others)
- `--workflow <name>` → load a workflow file, use its settings (see below)

### 0d-wf. Load workflow (if `--workflow` specified)

Search for the workflow file in order:
1. `_keeper/workflows/{name}.md` (project custom)
2. `workflows/{name}.md` (plugin templates)

Parse the frontmatter. Extract:
- `lenses` → overrides active lenses for this run (like `--lens` but multiple)
- `max-open-branches` → overrides `pr.maxOpenBranches` for this run
- `cadence` → informational only (cadence is handled by the tmux loop, not by run)

If the workflow file is not found, output error and STOP.

### 0e. Determine invocation context

Check if running interactively (Claude Code) or autonomously (tmux/bash):
- If `AskUserQuestion` is available and user is present → **supervised mode**
- If running via `/loop` → **repeating mode** (supervised between cycles)
- If neither → **autonomous mode** (no user interaction)

### 0f. Detect default branch

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

Record as `defaultBranch` (e.g., `main`, `master`, `develop`). Fallback to `main` if detection fails.

### 0g. Calibration check

Check `_keeper/memory.json` for uncalibrated lenses (where `calibratedOn` is null).

If uncalibrated lenses exist:
- **Supervised mode:** Use AskUserQuestion:
  - "Some lenses haven't been calibrated yet ({list}). Calibrate now?"
    - **Calibrate** — run `/keeper-calibrate` for uncalibrated lenses, then continue
    - **Skip** — proceed with defaults, calibrate later
- **Autonomous/repeating mode:** skip calibration, use defaults.

### 0h. Validate test runner (if code lenses active)

Run test command once to confirm it works. If fails: warn and disable code lenses for this session.

### 0i. Load toolbox

Read `.keeperrc.json` `toolbox.approvedTiers`. If `toolbox` section is missing, treat all tiers as unapproved (every Bash command will prompt).

Check for missing optional tiers and degrade gracefully:

| Missing Tier | Degradation |
|---|---|
| `git-write` | Doer makes changes in worktree but does not commit or push. Warn: "git-write tier not approved — commits disabled." |
| `test-runner` | Skip test validation (Step 0h). Disable test backpressure gate in doer context. Warn: "test-runner tier not approved — test gates disabled." |

Pass the `approvedTiers` list to doer prompts so the doer knows its constraints.

Output warnings (if any) before session start block.

### 0j. Initialize session

```
outerIteration = 0
sessionResults = []
maxIterations = from args or config (default: 15)
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper v{version} | run | ⚙️ Session started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{projectName} · {N} lenses active
Thresholds: CC ≤ {T}, coverage ≥ {T}%
Max iterations: {N}
Isolation: worktree (each lens batch gets its own branch)
Toolbox: {N} tiers approved {warnings if any}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 0.5: Branch Reconciliation

Before scanning, check the state of any open keeper branches to avoid duplicate work and enforce backpressure.

### 0.5a. Fetch and list remote keeper branches

```bash
git fetch --prune origin
git branch -r --list "origin/keeper/*"
```

**Graceful fallback:** If fetch fails (no remote, network error), skip the entire Step 0.5 with a warning:
```
⚠️ git fetch failed — skipping branch reconciliation
```

### 0.5b. Classify each branch

Cross-reference remote branches against `sessions.openBranches[]` in memory:

| State | How to detect | Action |
|-------|---------------|--------|
| **merged** | Branch in `git branch -r --merged origin/{defaultBranch}` | Confirm in memory — move targets to `refactoring.completedFunctions[]`. Remove branch entry. |
| **open** | Branch exists remotely, not merged | Add to skip list — these targets are pending review. Keep branch entry as-is. |
| **gone** | In memory but not on remote | Check if branch commits are reachable from default branch (`git merge-base --is-ancestor`). If yes → treat as merged. If no → treat as closed/rejected — remove targets, remove entry. These will be re-scanned. |

### 0.5c. Backpressure gate

Count open (unmerged, remote) keeper branches:

```bash
git branch -r --list "origin/keeper/*" --no-merged origin/{defaultBranch} | wc -l
```

Compare against `pr.maxOpenBranches` (default: 3).

If open branches >= threshold:
- **Supervised mode:** Ask user: `"⛔ {N}/{max} keeper branches open. Wait for merges or continue anyway?"`
  - **Wait** — STOP, output status and exit
  - **Continue** — proceed (user takes responsibility)
- **Autonomous mode:** STOP. Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | ⛔ {N}/{max} branches open — paused
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Waiting for branch merges before creating more work.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 0.5d. Build in-flight skip list

Collect all target functions/files from open branches in `sessions.openBranches[]`. Pass this list to the scanner as "in-flight functions" to skip.

---

## Step 1: SCAN

Spawn the scanner agent:
- `subagent_type`: `keeper:scanner`
- `description`: `Scan codebase (iteration {N})`
- Provide: source/exclude globs, threshold, active lenses, scan mode (`full` or filtered by `--lens`), completed functions, tagged files, human review list, **in-flight skip list** (from Step 0.5d)

Wait for results. Parse structured output.

**If `--dry-run`:** Display targets and STOP.
**If no targets found:** Go to Step 7 (Final Report — all clear).

---

## Step 2: PRIORITIZE

Rank all findings by severity across all lenses:

| Priority | Criteria |
|----------|----------|
| Critical | Broken tests, swallowed errors on I/O, docs drift on exported APIs |
| High | Complex functions (CC > 2x threshold), warning-level findings |
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

Output (include model indicator from lens frontmatter and branch count if applicable):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | {N} branches open | 🔧 {lens} | {model indicator}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Model indicators: `🟢 haiku` / `🟡 sonnet` / `🔴 opus` — read from the active lens's `model:` frontmatter field.

---

## Step 4: WORK

Dispatch to the lens's agent for a batch of targets (3-5 from the same lens). Each doer runs in worktree isolation — a fresh copy of the repo off the default branch.

Read the active lens's frontmatter for `model:` and `spawn:` fields:
- **model** — if it differs from the agent's default, pass as `model` override when spawning the agent
- **spawn** — include in the doer prompt so it knows its spawning permissions (`none`, `subagent`, or `team`)

### For code lenses (agent: doer)

For each target function, ONE AT A TIME:

Build the doer prompt with full context:
- Target function (name, file, lines, complexity, problem types)
- **Active lens name** — which lens flagged this function
- **Spawn permission** — from the lens's `spawn:` field (none, subagent, or team)
- Thresholds, test config
- Style preferences from memory
- Relevant techniques (worked/failed) from memory
- Relevant gotchas from memory
- Model context (first attempt on sonnet, or escalation context)

Spawn doer agent:
- `subagent_type`: `keeper:doer`
- `model`: from lens frontmatter `model:` field (override if different from agent default)
- `isolation`: `"worktree"`
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

### For labelling lens

Group unlabeled files into batches of ~20.

Spawn doer agent in labelling mode:
- `subagent_type`: `keeper:doer`
- `model`: from lens frontmatter `model:` field (haiku)
- `isolation`: `"worktree"`
- `description`: `labelling: batch ({N} files)`
- Provide: file paths, categories, header format, comment syntax, learned patterns, custom rules

The doer handles everything end-to-end in labelling mode — analyzes files, generates headers, applies them, and commits.

After labelling a batch → go to Step 5.

### For other doc lenses (agent: doer)

Spawn doer with the doc lens context and `isolation: "worktree"`. The doer handles JSDoc, markdown, and docs-coverage fixes the same way it handles code — one target at a time with verification.

---

## Step 5: PUSH & PR DESCRIPTION

After the doer returns from the worktree, create a properly named branch, push it, and generate a PR description.

### 5a. Check for changes

If the doer returned with no changes (worktree was auto-cleaned), skip to Step 6.

### 5b. Rename branch and push

The doer worked on the worktree's auto-generated branch. Rename it and push:

```bash
# From the worktree directory
git -C {worktree_path} branch -m keeper/{lens}-{YYYY-MM-DD-HHmm}
git -C {worktree_path} push -u origin keeper/{lens}-{YYYY-MM-DD-HHmm}
```

If `git-write` tier is not approved, skip the push and warn: "Branch ready locally but not pushed — git-write tier not approved."

### 5c. Generate PR description

Always generate this, regardless of platform:

```
Title: {type}({lens}): {short description}

## Summary
- **Lens**: {lens}
- **Branch**: `keeper/{lens}-{YYYY-MM-DD-HHmm}`
- **Files changed**: {N}
- **Targets addressed**: {list}

## Metrics
{before/after table for each target}

## What was done
{brief description of techniques applied}

🌿 Generated by Keeper
```

### 5d. Output

In supervised mode: Use AskUserQuestion:
- "Branch `keeper/{lens}-{timestamp}` pushed. What next?"
  - **I'll create the PR** — output title + description for copy-paste
  - **Continue working** — add more to this batch before pushing

In autonomous mode: push automatically, log the PR description to `_keeper/output/autonomous/{lens}-{timestamp}.md`.

### 5e. Record to memory

Add to `_keeper/memory.json` `sessions.openBranches[]`:
```json
{ "branch": "keeper/{lens}-{timestamp}", "lens": "...", "targets": ["functionName@file:line", ...], "pushedAt": "YYYY-MM-DDTHH:mm:ssZ" }
```

---

## Step 6: REMEMBER

Update `_keeper/memory.json`:

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
- If outside working hours → go to sleep: run `/keeper-sleep` logic, then PAUSE

---

## Step 7: CHECK EXIT CONDITIONS

### All clear
No targets found across any active lens:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | ✅ All clear
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

Remove lock file: `rm -f _keeper/.lock`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | 📊 Session Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{For each result:}
{✅|⚠️|🛑|⏱️} {target} — {lens} — {before}→{after}

Branches pushed: {N}
Open branches: {N} (of {max} allowed)
Merged since last run: {N}
Commits: {total}
Lenses worked: {list}

{If human review needed:}
📋 {N} target(s) need human review

{If promotion candidates:}
🔄 {N} extracted helper(s) — candidates for shared utility

Memory updated: _keeper/memory.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [S] Sleep · [L] Loop · [?] /keeper-help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

1. **You are the orchestrator.** Spawn agents, don't refactor code yourself.
2. **Re-scan after each batch.** Codebase changes. Get fresh results.
3. **One lens per branch.** Never mix labelling and refactoring in one branch.
4. **Parse agent reports carefully.** Extract all fields for memory updates.
5. **Escalate honestly.** Sonnet → opus → human review. Don't spin.
6. **Keep memory bounded.** Prune old entries.
7. **Worktree isolation.** All doer work runs in worktrees. Never switch branches in the main working directory.
8. **Show progress.** Output iteration headers and results.
9. **Respect schedule.** If sleeping hours → consolidate and pause.
10. **3-5 targets per lens batch.** Small branches. Midnight snacks.
11. **Reconcile branches before scanning.** Always run Step 0.5 before Step 1. Never create duplicate work for targets with open branches.
12. **Respect branch backpressure.** If open branches >= `pr.maxOpenBranches`, stop creating new work. Don't circumvent the gate.
13. **Lock file discipline.** Create `_keeper/.lock` at start, remove at end. This prevents nudge hooks from firing during runs.

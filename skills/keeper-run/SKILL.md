---
name: keeper-run
description: ▶️ Autonomous work loop — scan across lenses, pick highest-priority targets, dispatch to agents, create focused PRs. Designed for /loop and tmux integration.
user-invokable: true
disable-model-invocation: false
---

# Keeper Run — Autonomous Loop

Arguments: $ARGUMENTS (supports `--dry-run`, `--max-iterations N`, `--lens <name>`, `--workflow <name>`)

You are the orchestrator for the keeper plugin. You run the outer loop: scan through active lenses, pick the highest-priority work, dispatch to the right agent, handle results, create PRs, update memory, and loop until done or sleeping hours.

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
- `reviewers` → list of GitHub usernames to request review on PRs
- `auto-merge` → merge strategy (`squash`, `merge`, `rebase`) — enables `gh pr merge --auto`
- `max-open-prs` → overrides `pr.maxOpenPRs` for this run
- `cadence` → informational only (cadence is handled by the tmux loop, not by run)

If the workflow file is not found, output error and STOP.

### 0e. Determine invocation context

Check if running interactively (Claude Code) or autonomously (tmux/bash):
- If `AskUserQuestion` is available and user is present → **supervised mode**
- If running via `/loop` → **repeating mode** (supervised between cycles)
- If neither → **autonomous mode** (no user interaction)

### 0f. Git strategy (supervised mode only)

Use AskUserQuestion ONCE:
- "Branch strategy for this session?"
  - **Create branch** — keeper will create per-lens branches before each work batch
  - **Current branch** — work on whatever's checked out (all commits land here)
  - **Skip** — I'll handle git myself

Record the choice as `gitStrategy` (`create-branch`, `current-branch`, or `skip`).

In autonomous mode: always use `create-branch` strategy.

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
| `git-write` | Force `gitStrategy` to `skip`. Doer makes changes but does not commit. Warn: "git-write tier not approved — commits disabled." |
| `github` | Skip PR reconciliation (Step 0.5) and PR creation (Step 5). Warn: "github tier not approved — PRs disabled." |
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
Git strategy: {gitStrategy}
Toolbox: {N} tiers approved {warnings if any}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 0.5: PR Reconciliation

Before scanning, check the state of any open keeper PRs to avoid duplicate work and enforce backpressure.

### 0.5a. Query open PRs

```bash
gh pr list --search "head:keeper/" --json number,title,headRefName,state,mergeable,createdAt
```

**Graceful fallback:** If `gh` is unavailable or the command fails, skip the entire Step 0.5 with a warning:
```
⚠️ gh CLI unavailable — skipping PR reconciliation
```

### 0.5b. Classify each PR

For each PR returned:

| State | Action |
|-------|--------|
| **merged** | Confirm in memory — move targets from `sessions.openPRs[]` to `refactoring.completedFunctions[]`. Remove PR entry. |
| **open, mergeable** | Add to skip list — these targets are pending review. Keep PR entry as-is. |
| **closed (not merged)** | Revert in memory — remove targets from `completedFunctions[]`, remove PR entry. These will be re-scanned. |
| **open, conflicted** | Flag for human attention. In supervised mode: notify user. In autonomous mode: log warning. |

### 0.5b-ext. Extended PR checks (workflow-driven)

If a workflow is active, run additional checks on open PRs:

**CI status:**
```bash
gh pr checks {number} --json name,state,conclusion
```
- All passed → PR is healthy, waiting for review
- Any failed → flag for human attention in supervised mode, log warning in autonomous mode

**Review status:**
```bash
gh pr view {number} --json reviews,reviewRequests
```
- Changes requested → flag for human attention (review feedback loop is deferred — keeper does not auto-fix review comments yet)
- Approved → if auto-merge is enabled, GitHub handles it automatically

Without a workflow, skip these extended checks (backwards compatible).

### 0.5c. Backpressure gate

Count open (non-merged, non-closed) keeper PRs. Compare against `pr.maxOpenPRs` (default: 3).

If open PRs >= threshold:
- **Supervised mode:** Ask user: `"⛔ {N}/{max} keeper PRs open. Wait for reviews or continue anyway?"`
  - **Wait** — STOP, output status and exit
  - **Continue** — proceed (user takes responsibility)
- **Autonomous mode:** STOP. Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | ⛔ {N}/{max} PRs open — paused
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Waiting for PR reviews before creating more work.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 0.5d. Build in-flight skip list

Collect all target functions/files from open PRs in `sessions.openPRs[]`. Pass this list to the scanner as "in-flight functions" to skip.

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

Output (include model indicator from lens frontmatter and PR count if applicable):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | run | {N} PRs open | 🔧 {lens} | {model indicator}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Model indicators: `🟢 haiku` / `🟡 sonnet` / `🔴 opus` — read from the active lens's `model:` frontmatter field.

---

## Step 3.5: BRANCH (before work)

If `gitStrategy` is `create-branch`:

```bash
git checkout -b keeper/{lens}-{YYYY-MM-DD-HHmm}
```

This ensures the doer's commits land on an isolated per-lens branch, not on main. If the branch already exists (e.g., retrying after a stall), check it out instead of creating.

If `gitStrategy` is `current-branch` or `skip`: no branch change — commits land on the current branch.

---

## Step 4: WORK

Dispatch to the lens's agent for a batch of targets (3-5 from the same lens).

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
- `description`: `labelling: batch ({N} files)`
- Provide: file paths, categories, header format, comment syntax, learned patterns, custom rules

The doer handles everything end-to-end in labelling mode — analyzes files, generates headers, applies them, and commits.

After labelling a batch → go to Step 5.

### For other doc lenses (agent: doer)

Spawn doer with the doc lens context. The doer handles JSDoc, markdown, and docs-coverage fixes the same way it handles code — one target at a time with verification.

---

## Step 5: PR

Create a PR for the completed batch. One lens per PR.

The branch was already created in Step 3.5 — commits from the doer are already on `keeper/{lens}-{YYYY-MM-DD-HHmm}`.

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

🌿 Generated by Keeper
PREOF
)"
```

### PR lifecycle (workflow-driven)

After `gh pr create`, if a workflow is active:

**Reviewers** — if `reviewers` is set in the workflow:
```bash
gh pr edit {number} --add-reviewer {reviewer1},{reviewer2}
```

**Auto-merge** — if `auto-merge` is set in the workflow:
```bash
gh pr merge {number} --auto --{strategy}
```

This tells GitHub to merge automatically when all checks pass and reviews are approved. Keeper doesn't wait — it moves on to the next batch.

If no workflow is active, or the workflow doesn't specify reviewers/auto-merge, skip these steps (backwards compatible).

After PR creation, record to `_keeper/memory.json` `sessions.openPRs[]`:
```json
{ "number": N, "lens": "...", "branch": "keeper/...", "targets": ["functionName@file:line", ...], "status": "pending", "createdAt": "YYYY-MM-DDTHH:mm:ssZ" }
```

Then switch back to main branch for next cycle:
```bash
git checkout {original branch}
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

PRs created: {N}
PRs open: {N} (of {max} allowed)
PRs merged since last run: {N}
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
3. **One lens per PR.** Never mix labelling and refactoring in one PR.
4. **Parse agent reports carefully.** Extract all fields for memory updates.
5. **Escalate honestly.** Sonnet → opus → human review. Don't spin.
6. **Keep memory bounded.** Prune old entries.
7. **Ask git strategy ONCE.** Not per function or lens.
8. **Show progress.** Output iteration headers and results.
9. **Respect schedule.** If sleeping hours → consolidate and pause.
10. **3-5 targets per lens batch.** Small PRs. Midnight snacks.
11. **Reconcile PRs before scanning.** Always run Step 0.5 before Step 1. Never create duplicate work for targets with open PRs.
12. **Respect PR backpressure.** If open PRs >= `pr.maxOpenPRs`, stop creating new work. Don't circumvent the gate.
13. **Lock file discipline.** Create `_keeper/.lock` at start, remove at end. This prevents nudge hooks from firing during runs.

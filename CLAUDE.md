# keeper

Autonomous repository hygiene agent. Scans, labels, untangles, and tends codebases with brain-inspired memory and sleep cycles.

## Architecture

**Everything is a lens.** A lens is a self-contained analysis dimension — what to detect, which agent handles fixes, how to package changes into PRs. Keeper has 12 lenses (8 code, 4 docs).

## Structure

```
keeper/
├── personality.md                   # Keeper voice, output format, principles
├── .claude-plugin/plugin.json       # Plugin manifest v1.3.0
├── agents/
│   ├── scanner.md                   # Unified multi-lens scanner (haiku)
│   └── doer.md                      # Universal worker — all 12 lenses (model per lens)
├── skills/                          # 7 skills (all user-invokable)
│   ├── setup/SKILL.md               # Bootstrap config + memory + encyclopedia
│   ├── scan/SKILL.md                # Quick read-only health report
│   ├── run/SKILL.md                 # Autonomous work loop
│   ├── sleep/SKILL.md               # Memory consolidation + housekeeping
│   ├── deploy/SKILL.md              # Workflow deployment helper
│   ├── help/SKILL.md                # Visual overview + interactive Q&A
│   └── complexity-scorer/SKILL.md   # SonarQube algorithm fallback
├── hooks/
│   └── hooks.json                   # Nudge mode hooks (PostToolUse + UserPromptSubmit)
├── workflows/                       # Daemon workflow templates
│   ├── code-quality.md              # Untangling + micro-hygiene + error-handling, 4h
│   ├── docs-hygiene.md              # Labelling + jsdoc + docs-coverage, daily
│   └── full-service.md              # All 12 lenses, 4h, copilot review, auto-merge
├── scripts/
│   ├── lib.sh                        # Shared guards and helpers
│   ├── nudge-collect.sh              # Append edited file paths to queue (no analysis)
│   └── nudge-inject.sh              # Inject queue on next user message after cooldown
├── lenses/                          # 8 code + 4 docs lenses
│   ├── untangling.md                # code · function
│   ├── modernization.md             # code · function
│   ├── testability.md               # code · function
│   ├── boundaries.md                # code · function+module
│   ├── micro-hygiene.md             # code · function
│   ├── type-safety.md               # code · function (TS)
│   ├── friction.md                  # code · module
│   ├── error-handling.md            # code · function+module
│   ├── labelling.md                 # docs · file
│   ├── jsdoc.md                     # docs · function
│   ├── markdown.md                  # docs · file
│   └── docs-coverage.md             # docs · module
├── .claude/skills/
│   └── lib-readme/SKILL.md          # Repo-level: self-tending README generator
└── plan/                            # Implementation phases
```

## Operating Modes (3+1)

| Mode | Trigger | Mechanism |
|------|---------|-----------|
| **+1 Onboarding** | User learns/configures | setup, help, scan skills |
| **Supervised** | User invokes `/keeper:run` | run skill, doer agent |
| **Daemon** | Workflow + tmux from deploy | run --workflow, tmux sessions |
| **Nudge** | User edits a file | PostToolUse hook → collect → UserPromptSubmit hook → inject → haiku scanner |

**Nudge mode:** Collect-then-analyze pipeline. PostToolUse (Write|Edit) runs `scripts/nudge-collect.sh` which appends the edited file path to `_keeper/nudge-queue.txt` (no analysis, just collection). When the user sends their next message after cooldown elapses (default 30 min), UserPromptSubmit runs `scripts/nudge-inject.sh` which outputs the queue as additional context. Claude then spawns a haiku scanner subagent scoped to those files, running only the configured nudge lenses (default: labelling, micro-hygiene, jsdoc). All detection logic stays in lenses — shell scripts do zero analysis. Guards: lock file (`_keeper/.lock`) prevents nudge during keeper operations.

## Runtime Files (created in target project)

```
{project}/
├── .keeperrc.json                   # Config (procedural memory)
└── _keeper/
    ├── memory.json                  # Short-term memory
    ├── .lock                        # Present during keeper operations (run/scan/sleep)
    ├── workflows/                   # User-created workflow files
    ├── nudge-queue.txt              # Edited file paths awaiting lens scan (transient)
    ├── nudge-last                   # Last nudge timestamp (plain text, one line)
    ├── nudge.conf                   # Nudge config (key=value, written by setup)
    ├── output/
    │   ├── supervised/              # Interactive session output
    │   └── autonomous/              # Daemon/background output
    ├── encyclopedia/                # Long-term memory (articles)
    │   ├── architecture.md
    │   ├── patterns.md
    │   ├── gotchas.md
    │   ├── taxonomy.md
    │   └── conventions.md
    ├── history.md                   # Heritage, moments
    └── briefing.md                  # Morning briefing
```

## Memory Model

- **Working memory** = conversation context (ephemeral)
- **Short-term** = `_keeper/memory.json` (session results, pending consolidation, open PR tracking via `sessions.openPRs[]`)
- **Long-term** = `_keeper/encyclopedia/` (proven patterns, promoted during sleep)
- **Procedural** = `.keeperrc.json` (calibrated preferences, thresholds)

## Multi-Model Routing

Each lens declares its own `model:` and `spawn:` in frontmatter. The orchestrator reads these at dispatch time. All lenses use the doer agent; model/spawn override per lens.

| Lens | Model | Spawn | Rationale |
|------|-------|-------|-----------|
| micro-hygiene | haiku | none | Simple single-file transforms |
| jsdoc | haiku | none | Mechanical doc additions |
| labelling | haiku | none | Batch file classification (doer labelling mode) |
| untangling | sonnet | none | Structural reasoning |
| modernization | sonnet | none | Paradigm-level reasoning |
| testability | sonnet | subagent | Needs to explore test files, deps |
| error-handling | sonnet | subagent | Must trace error paths across callers |
| markdown | sonnet | none | Content quality judgment |
| type-safety | sonnet | team | Cross-file type graph analysis |
| boundaries | sonnet | subagent | Module boundary = multi-file |
| friction | sonnet | subagent | Scattered concept detection |
| docs-coverage | sonnet | subagent | Directory structure scanning |

**Spawn modes:** `none` = no subagents. `subagent` = up to 3 read-only Explore subagents. `team` = Map/Plan/Execute multi-file coordination.

**Escalation:** sonnet stalls → opus + stall context (unchanged).

**Fallback:** Lenses without `model:` use agent default. Without `spawn:` → treat as `none`.

## PR Lifecycle

Keeper tracks PRs it creates and reconciles them before each scan cycle.

1. **Create** — after each lens batch, `gh pr create` and record to `sessions.openPRs[]`
2. **Reconcile** (Step 0.5 of run) — query `gh pr list --search "head:keeper/"`, classify each:
   - **merged** → confirm in memory, move targets to completed
   - **open** → add targets to in-flight skip list
   - **closed (rejected)** → revert memory, targets will be re-scanned
   - **conflicted** → flag for human attention
3. **Backpressure** — if open PRs >= `pr.maxOpenPRs` (default 3), stop creating new work
4. **Fallback** — if `gh` CLI unavailable, skip reconciliation with warning

## Key Patterns

- Lenses define detection + agent assignment; PR batching strategy is orchestrator-level (run skill)
- Progressive calibration: labelling and untangling calibrate on first supervised run (see `skills/run/SKILL.md` Step 0g); other lenses use config defaults
- One lens per PR ("midnight snacks")
- Sleep consolidation: triage → consolidate → prune → integrate → plan → brief → housekeep
- Backpressure gates: tests pass, coverage held, complexity down, signature unchanged
- Escalation: sonnet stalls → opus + stall context
- PR lifecycle: create → reconcile → backpressure gate
- Lock file (`_keeper/.lock`): created by run/scan/sleep, prevents nudge hooks from firing during operations

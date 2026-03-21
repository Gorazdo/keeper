# keeper

Autonomous repository hygiene agent. Scans, labels, untangles, and tends codebases with brain-inspired memory and sleep cycles.

## Architecture

**Everything is a lens.** A lens is a self-contained analysis dimension — what to detect, which agent handles fixes, how to package changes into PRs. Keeper has 12 lenses (8 code, 4 docs).

## Structure

```
keeper/
├── .claude-plugin/plugin.json      # Plugin manifest v1.0.0
├── agents/
│   ├── personality.md               # Keeper voice, output format, principles
│   ├── scanner.md                   # Unified multi-lens scanner (haiku)
│   ├── doer.md                      # Code refactoring agent (sonnet/opus)
│   └── tagger.md                    # File labelling agent (haiku)
├── commands/
│   ├── setup.md                     # Bootstrap config + memory + encyclopedia
│   ├── scan.md                      # Quick read-only health report
│   ├── run.md                       # Autonomous work loop
│   ├── sleep.md                     # Memory consolidation
│   └── deploy.md                    # Generate tmux/bash scripts
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
├── skills/
│   ├── complexity-scorer/SKILL.md   # SonarQube algorithm fallback
│   └── housekeeping/SKILL.md        # Runtime file structure enforcement
└── plan/                            # Implementation phases
```

## Runtime Files (created in target project)

```
{project}/
├── .keeperrc.json                   # Config (procedural memory)
└── _keeper/
    ├── memory.json                  # Short-term memory
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
    ├── briefing.md                  # Morning briefing
    └── daemon.sh                    # Generated daemon script
```

## Memory Model

- **Working memory** = conversation context (ephemeral)
- **Short-term** = `_keeper/memory.json` (session results, pending consolidation, open PR tracking via `sessions.openPRs[]`)
- **Long-term** = `_keeper/encyclopedia/` (proven patterns, promoted during sleep)
- **Procedural** = `.keeperrc.json` (calibrated preferences, thresholds)

## Multi-Model Routing

Each lens declares its own `model:` and `spawn:` in frontmatter. The orchestrator reads these at dispatch time.

| Lens | Model | Spawn | Rationale |
|------|-------|-------|-----------|
| micro-hygiene | haiku | none | Simple single-file transforms |
| jsdoc | haiku | none | Mechanical doc additions |
| labelling | haiku | none | Classification, no reasoning |
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

- Lenses define detection + agent + PR strategy
- Progressive calibration: each lens calibrates on first use
- One lens per PR ("midnight snacks")
- Sleep consolidation: triage → consolidate → prune → integrate → plan → brief
- Backpressure gates: tests pass, coverage held, complexity down, signature unchanged
- Escalation: sonnet stalls → opus + stall context
- PR lifecycle: create → reconcile → backpressure gate

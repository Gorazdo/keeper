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
│   └── complexity-scorer/SKILL.md   # SonarQube algorithm fallback
└── plan/                            # Implementation phases
```

## Runtime Files (created in target project)

```
{project}/
├── .keeperrc.json                   # Config (procedural memory)
├── .keeper-memory.json              # Short-term memory
└── _keeper/
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
- **Short-term** = `.keeper-memory.json` (session results, pending consolidation)
- **Long-term** = `_keeper/encyclopedia/` (proven patterns, promoted during sleep)
- **Procedural** = `.keeperrc.json` (calibrated preferences, thresholds)

## Multi-Model Routing

| Task | Model |
|------|-------|
| Scanning, labelling | haiku |
| Code refactoring | sonnet |
| Hard problems, escalation | opus |

## Key Patterns

- Lenses define detection + agent + PR strategy
- Progressive calibration: each lens calibrates on first use
- One lens per PR ("midnight snacks")
- Sleep consolidation: triage → consolidate → prune → integrate → plan → brief
- Backpressure gates: tests pass, coverage held, complexity down, signature unchanged
- Escalation: sonnet stalls → opus + stall context

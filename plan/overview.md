# Keeper — Implementation Plan

8 phases, each self-contained with its files and deliverables.

| Phase | Name | Key Files | Status |
|-------|------|-----------|--------|
| 1 | [Skeleton & Personality](phase-1-skeleton.md) | plugin.json, personality.md, CLAUDE.md | ✅ |
| 2 | [Config & Memory](phase-2-config.md) | setup.md, schemas | ✅ |
| 3 | [Scanning & Code Lenses](phase-3-scanning.md) | scanner.md, scan.md, 8 lenses, complexity-scorer | ✅ |
| 4 | [Code Lens Execution](phase-4-code-lenses.md) | doer.md, progressive calibration | ✅ |
| 5 | [Doc Lenses](phase-5-doc-lenses.md) | tagger.md, 4 doc lenses | ✅ |
| 6 | [Run Loop & PRs](phase-6-run-loop.md) | run.md | ✅ |
| 7 | [Sleep & Encyclopedia](phase-7-sleep.md) | sleep.md | ✅ |
| 8 | [Deploy & Polish](phase-8-deploy.md) | deploy.md, marketplace | ✅ |

## Source Plugins

Features cherry-picked from:
- `untangle-with-ralph-loop` → 8 code lenses, doer, scanner, complexity-scorer, backpressure gates
- `dossier` → labelling lens, tagger agent, header formats
- `gary-the-gardener` → personality, heritage/moments, docs health

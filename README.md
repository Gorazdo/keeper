# keeper

Autonomous repository hygiene for [Claude Code](https://claude.ai/claude-code).
Scans your codebase through **lenses**, creates small focused PRs while you sleep.

## User Journey

**1. Bootstrap** — `/keeper:setup`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.1.0 | setup | ✅ Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

my-app · TypeScript/Next.js
8 lenses active · test runner: vitest

Files created:
  .keeperrc.json          config
  _keeper/memory.json     short-term memory
  _keeper/output/         scan output (supervised/autonomous)
  _keeper/encyclopedia/   long-term memory (5 articles)
  _keeper/briefing.md     morning briefing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [S] Scan now · [X] Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**2. Health check** — `/keeper:scan`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.1.0 | scan | 8 lenses active
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 untangling    3 functions · processOrder CC 24
🧪 testability   2 exports without tests
⚠️ error-handling 1 swallowed exception
🏷️ labelling     14 files unlabelled
📝 jsdoc         9 exports missing docs

Top priorities:
  1. processOrder — complexity 24 (threshold 10)
  2. handleWebhook — swallowed error on I/O path
  3. src/api/ — 14 files need category headers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [R] Run · [D] Details · [X] Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**3. Autonomous loop** — `/keeper:run`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.1.0 | run | 📊 Session Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ processOrder    — CC: 24→8   cov: 72%→86%
✅ validateInput   — CC: 18→6   cov: 65%→91%
✅ 14 files labelled with category headers
⚠️ handleWebhook  — stalled (needs human review)

PRs created: 2 · Commits: 7
Lenses worked: untangling, labelling

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Lenses

| | Lens | Detects |
|---|---|---|
| 🔧 | untangling | Deep nesting, boolean chains, too many responsibilities |
| 🔄 | modernization | Imperative→declarative, callbacks→async, stringly-typed |
| 🧪 | testability | Untested exports, no seams, logic tangled with effects |
| 🧱 | boundaries | Shallow, leaky, or blurred interfaces |
| 🧹 | micro-hygiene | Unnecessary mutability, manual work, redundant verbosity |
| 🔒 | type-safety | `any` usage, assertions, missing return types |
| 🔗 | friction | Scattered concepts, test deserts |
| ⚠️ | error-handling | Swallowed errors, inconsistent strategies, missing paths |

| | Lens | Detects |
|---|---|---|
| 🏷️ | labelling | Files without category headers |
| 📝 | jsdoc | Missing or incomplete JSDoc |
| 📄 | markdown | Markdown structure and content quality |
| 📋 | docs-coverage | Documentation gaps and drift |

## Commands

```
/keeper:setup    Bootstrap config, detect stack, choose lenses
/keeper:scan     Read-only health report across active lenses
/keeper:run      Autonomous loop — scan → pick → fix → PR → repeat
/keeper:sleep    Consolidate learnings into long-term memory
/keeper:deploy   Generate tmux script for background daemon
```

## Memory

- **Short-term** `_keeper/memory.json` — session results, pending consolidation
- **Long-term** `_keeper/encyclopedia/` — proven patterns, promoted during sleep
- **Procedural** `.keeperrc.json` — calibrated preferences and thresholds

Sleep consolidation promotes learnings to encyclopedia, prunes noise, and writes a morning briefing.

## Install

```bash
claude plugin install keeper@gorazdo-plugins
# or local development
claude --plugin-dir /path/to/keeper
```

MIT

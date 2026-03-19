# keeper

Autonomous repository hygiene agent for Claude Code.

Scans your codebase through **lenses** — self-contained analysis dimensions — and creates small, focused PRs to improve code quality, documentation, and organization.

## Lenses

### Code Lenses
| Lens | What it finds |
|------|---------------|
| untangling | Deep nesting, boolean chains, too many responsibilities |
| modernization | Imperative→declarative, callbacks→async, stringly-typed |
| testability | Untested exports, no seams, logic tangled with effects |
| boundaries | Shallow, leaky, or blurred interfaces |
| micro-hygiene | Unnecessary mutability, manual work, redundant verbosity |
| type-safety | `any` usage, assertions, missing return types |
| friction | Scattered concepts, test deserts |
| error-handling | Swallowed errors, inconsistent strategies, missing error paths |

### Docs Lenses
| Lens | What it finds |
|------|---------------|
| labelling | Files without category headers |
| jsdoc | Missing or incomplete JSDoc comments |
| markdown | Markdown structure and content quality |
| docs-coverage | Documentation gaps and drift |

## Commands

```bash
/keeper:setup      # Bootstrap config and memory
/keeper:scan       # Quick health report across active lenses
/keeper:run        # Autonomous work loop — scan → pick lens → work → PR → repeat
/keeper:sleep      # Consolidate learnings into long-term memory
/keeper:deploy     # Generate tmux/bash script for autonomous background running
```

## How to Run

```bash
# Interactive (supervised)
/keeper:run

# Repeating on interval
/loop 4h /keeper:run

# Fully autonomous (via tmux)
/keeper:deploy     # generates keeper-daemon.sh
```

## Memory

Keeper uses brain-inspired memory:
- **Short-term** (`.keeper-memory.json`) — session results, active patterns
- **Long-term** (`_keeper/encyclopedia/`) — proven patterns, promoted during sleep
- **Sleep consolidation** — during off-hours, consolidates learnings and plans next session

## Install

```bash
claude plugin install keeper@gorazdo-plugins
# or local
claude --plugin-dir /path/to/keeper
```

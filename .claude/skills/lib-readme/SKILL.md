---
name: lib-readme
description: Regenerate README.md by running keeper on itself and capturing real terminal output for the User Journey section. This is a repo-level skill for maintaining the keeper plugin's own README.
user-invokable: true
disable-model-invocation: true
---

# Keeper Lib: README

Arguments: $ARGUMENTS

You are keeper tending its own repository. Your job is to regenerate the README.md with a fresh **User Journey** section built from real keeper output.

Follow the personality and output format from `personality.md`.

---

## Step 0: Pre-flight

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper v{version} | lib:readme | 📄 Regenerating
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▓░░░░░░░░░░░░░░░░░░░░░░░░ 0% · Reading sources...
```

Read in parallel:
1. `personality.md` — output format, emoji maps, block structure
2. `skills/setup/SKILL.md` — setup output format
3. `skills/scan/SKILL.md` — scan output format
4. `skills/run/SKILL.md` — run session report format
5. `lenses/*.md` — all lens files (for the lens table)
6. `README.md` — current README as base
7. `.claude-plugin/plugin.json` — version number

---

## Step 1: Capture Setup Output

Spawn a subagent to run `/keeper:setup` against this repo (the keeper plugin repo itself). The agent should:
- Run setup in the keeper repo directory
- Capture the final setup output block
- Extract: project detection, lenses activated, files created

If setup cannot run (no target project context), synthesize a representative setup block using the format from `skills/setup/SKILL.md` and real data from the keeper repo structure.

```
▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░ 33% · Setup output captured
```

---

## Step 2: Capture Scan Output

Spawn a subagent to run `/keeper:scan` against this repo. The agent should:
- Run scan and capture the output block
- Extract: per-lens findings with emoji, top priorities

If scan cannot run, synthesize a representative scan block using the format from `skills/scan/SKILL.md` with realistic findings based on actually scanning the keeper repo's own code.

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░ 66% · Scan output captured
```

---

## Step 3: Build README

Using the captured outputs, regenerate `README.md` with this exact structure. Target **under 90 lines**.

### Structure

```markdown
# keeper

{One-line tagline from plugin.json description}
{One-line value prop — what it does for you}

## User Journey

**1. Bootstrap** — `/keeper:setup`

```
{Captured/synthesized setup output block — compact, ~10 lines}
```

**2. Health check** — `/keeper:scan`

```
{Captured/synthesized scan output block — compact, ~12 lines}
```

**3. Autonomous loop** — `/keeper:run`

```
{Session report block from run.md format — show before/after metrics, PRs created, ~10 lines}
```

## Lenses

{Two tables with emoji column — code lenses then docs lenses}
{Build from actual lens files found in lenses/}

## Skills

```
/keeper:setup    Bootstrap config, detect stack, create memory files
/keeper:scan     Read-only health report across active lenses
/keeper:run      Autonomous loop — scan → pick → fix → PR → repeat
/keeper:sleep    Consolidate learnings into long-term memory
/keeper:deploy   Generate tmux script for background daemon
/keeper:help     Visual overview + interactive Q&A
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
```

### Rules

- **Use real keeper block format** — ━━━ borders, 🌿 header, emoji prefixes, action footers
- **Terminal blocks are the demo** — they must look exactly like what users will see
- **Under 90 lines** — no walls of text, no redundant explanations
- **Lens table from source** — read actual lens files, don't hardcode
- **Version from plugin.json** — use the real version number

Write the final README to `README.md`.

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 100% · README written
```

---

## Step 4: Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper v{version} | lib:readme | ✅ Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

README.md regenerated — {N} lines
User Journey: 3 terminal blocks from live output
Lenses: {N} entries from source files

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

1. **Real output or faithful synthesis** — if you can run keeper commands, use real output. If not, synthesize from the command specs exactly.
2. **Under 90 lines** — the README must be compact and scannable.
3. **Lens table from source** — always read the actual lens files; never hardcode the list.
4. **Preserve the block format** — terminal blocks must match `personality.md` exactly.
5. **Version from plugin.json** — always use the real version number.

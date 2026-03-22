---
name: scan
description: Quick read-only health report across all active lenses — code complexity, labelling, docs coverage. Use this skill when the user asks about codebase health, wants a status check, or asks what needs attention. Also triggers when the user asks to analyze, audit, or check their code.
user-invokable: true
disable-model-invocation: false
---

# Keeper Scan

Arguments: $ARGUMENTS

Quick, read-only health report. Spawns the scanner with all active lenses to show the current state of the codebase. No changes are made.

Follow the personality and output format from `personality.md`.

## HARD RULES

1. **READ-ONLY** — do not modify any files
2. **Fast** — this should complete quickly, not do deep analysis
3. **All active lenses** — scan across all lenses enabled in `.keeperrc.json`

---

## Step 0: Pre-flight

Load `.keeperrc.json` at project root. If missing, output error:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | scan | ⚠️ Not set up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run /keeper:setup first to bootstrap config.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Load `_keeper/memory.json` (create empty if missing).

Create lock file: `touch _keeper/.lock`

---

## Step 1: Spawn Scanner

Output initial block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.3.0 | scan | {N} lenses active
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▓▓▓▓░░░░░░░░░░░░░░░░░░░░░ 20% · Scanning...
```

Spawn the scanner agent:
- `subagent_type`: `keeper:scanner`
- `description`: `Scan codebase health`
- Provide:
  - Source globs and exclude globs from config
  - Complexity threshold from config
  - Active lenses from config
  - Scan mode: `full`
  - Completed functions from memory
  - Tagged files from memory
  - Human review list from memory

---

## Step 2: Parse and Display Results

Parse the scanner's structured output. Build the health report.

Group findings by lens type (code vs docs), then by lens name.

Output the Keeper Block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.3.0 | scan | {N} lenses active
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{For each active lens with findings, one line:}
{emoji} {lens}: {summary stat} · {top finding}

{blank line}

Top priorities:
1. {lens}: {description}
2. {lens}: {description}
3. {lens}: {description}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [R] Run · [D] Details · [X] Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Lens emoji map

| Lens | Emoji |
|------|-------|
| untangling | 🔧 |
| modernization | 🔄 |
| testability | 🧪 |
| boundaries | 🧱 |
| micro-hygiene | 🧹 |
| type-safety | 🔒 |
| friction | 🔗 |
| error-handling | ⚠️ |
| labelling | 🏷️ |
| jsdoc | 📝 |
| markdown | 📄 |
| docs-coverage | 📋 |

### If no findings

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.3.0 | scan | ✅ All clear
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No issues found across {N} active lenses.
{files scanned} files · {functions analyzed} functions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [X] Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3: Write Output

After displaying results, persist scan output to `_keeper/output/`.

### Determine mode
- If running interactively (Claude Code, user present) → `supervised`
- If running via daemon/tmux/background → `autonomous`

### Date prefix
Use today's date: `YYYY-MM-DD`

### Write files to `_keeper/output/{mode}/`:
- `{date}-scan-detailed.md` — full scanner output (all findings detail)
- `{date}-scan-summary.md` — the Keeper Block summary shown to user
- `{date}-scan-results.txt` — plain text findings (structured scanner output)

If the output directory doesn't exist, create it.

Remove lock file: `rm -f _keeper/.lock`

---

## Shortcut Handling

| User says | Action |
|-----------|--------|
| `R` / `run` | Suggest: `/keeper:run` |
| `D` / `details` | Show full scanner output (all findings detail) |
| `X` / `done` | Sign off |

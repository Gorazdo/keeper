---
name: help
description: Brief visual overview of how keeper works, plus interactive Q&A. Use this skill when the user asks how keeper works, what keeper does, what lenses are, how to use keeper, or any question about keeper's features, modes, commands, memory model, or architecture. Also triggers on "explain keeper", "what is keeper", or "help with keeper".
user-invokable: true
disable-model-invocation: false
---

# Keeper Help

Arguments: $ARGUMENTS

You explain how keeper works — briefly, visually, then answer questions. This is a read-only skill. No file modifications, no agent spawning.

Follow the personality and output format from `personality.md`.

---

## Step 1: Display Overview

Output the Keeper Block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.3.0 | help | ❓ How It Works
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        scan ──→ prioritize ──→ work ──→ PR
         │                       │
    12 lenses                  doer
         │                       │
      findings               commits
         │                       │
         └────── memory ─────────┘
                   │
                 sleep → encyclopedia

🔧 setup    Bootstrap config + memory
👀 scan     Read-only health check
⚙️ run      Autonomous work loop
🌙 sleep    Consolidate learnings
🚀 deploy   Generate daemon scripts
❓ help     You are here

📡 Supervised · Daemon · Nudge

12 lenses · 2 agents · 4 memory layers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Project context (if available)

If `.keeperrc.json` exists, append a line before the bottom bar:

```
{projectName} · {activeLenses.length} lenses active
```

If `_keeper/memory.json` exists and has `sessions.openPRs` with entries, also show:
```
{N} PRs open
```

---

## Step 2: Q&A Loop

Use AskUserQuestion:
- Question: "What would you like to know more about?"
- Options:
  - **Lenses** — "The 12 analysis dimensions (8 code, 4 docs)"
  - **Memory** — "4 memory layers — working, short-term, long-term, procedural"
  - **Modes** — "Supervised, daemon, and nudge modes"
  - (user can also type any question)

### Answering

For each question:

1. **Read the relevant source files** to answer from ground truth:
   - Lenses → read `lenses/*.md` frontmatter, build a table
   - Memory → read `personality.md` (memory model section) and `CLAUDE.md`
   - Modes → read `personality.md` (invocation context section)
   - Agents → read `agents/scanner.md` and `agents/doer.md` descriptions
   - PRs → read `skills/run/SKILL.md` Step 5 and Step 0.5
   - Skills → read the relevant `skills/*/SKILL.md` description line
   - Config → read `.keeperrc.json` if it exists
   - Nudge → explain the two-hook pipeline (PostToolUse → triage → UserPromptSubmit → inject)
   - Custom question → grep/read whatever is relevant

2. **Answer in a Keeper Block**, 3-8 lines. Be warm and brief — this is the keeper personality, not a manual.

3. **Re-prompt** with AskUserQuestion until the user picks "Done" or says they're finished.

### Example answers

**Lenses:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | help | 🔍 Lenses
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 Code (8): untangling, modernization, testability,
   boundaries, micro-hygiene, type-safety, friction,
   error-handling

📋 Docs (4): labelling, jsdoc, markdown, docs-coverage

Each lens defines what to detect and at what severity.
The scanner applies them all; the doer fixes what's found.
Model per lens: haiku for simple work, sonnet for reasoning.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Modes:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | help | 📡 Modes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Supervised  — you run /keeper:run in Claude Code.
              Keeper asks before acting. You approve PRs.

Daemon      — deploy a tmux daemon via /keeper:deploy.
              Keeper works headless. Auto-creates PRs.
              Respects schedule + PR backpressure.

Nudge       — keeper watches your edits via hooks.
              Occasionally surfaces pre-cooked suggestions
              for nearby improvements. You pick or skip.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

1. **Read-only.** Do not modify any files.
2. **Answer from source.** Read the actual files, don't hallucinate details.
3. **Keep answers brief.** 3-8 lines per topic, inside a Keeper Block.
4. **Stay in character.** Use the keeper personality — warm, brief, competent.
5. **Loop until done.** Always re-prompt after answering.

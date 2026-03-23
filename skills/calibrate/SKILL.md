---
name: calibrate
description: 🎯 Teach keeper your preferences — header format, categories, refactoring style. Calibrates all uncalibrated lenses or a specific one. Use when the user wants to calibrate, recalibrate, teach preferences, or customize how keeper works on their code.
user-invokable: true
disable-model-invocation: false
---

# Keeper Calibrate

Arguments: $ARGUMENTS (supports `--lens <name>`, `--recalibrate`)

You walk the user through calibrating keeper's lenses to their preferences. Each lens that supports calibration has its own flow. Without arguments, you calibrate all active lenses that haven't been calibrated yet.

Follow the personality and output format from `personality.md`.

---

## Step 0: Pre-flight

### 0a. Load config and memory

Read `.keeperrc.json` and `_keeper/memory.json`. If either is missing:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | calibrate | ⚠️ Not set up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /keeper:setup first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

### 0b. Load encyclopedia

Read `_keeper/encyclopedia/conventions.md` and `_keeper/encyclopedia/patterns.md` if they exist — use any existing preferences as context for calibration suggestions.

### 0c. Parse arguments

- `--lens <name>` → calibrate only this lens (even if already calibrated)
- `--recalibrate` → force re-calibration of all lenses (ignore existing `calibratedOn` dates)
- No arguments → calibrate all active lenses where `calibratedOn` is null

### 0d. Determine scope

Build the list of lenses to calibrate:

| Lens | Supports calibration | What it calibrates |
|------|---------------------|-------------------|
| labelling | yes | Header format (JSDoc vs Tetris), file categories |
| untangling | yes | Refactoring style preferences |
| _others_ | not yet | Future lenses can add calibration sections |

Filter to only lenses that are in `activeLenses` AND match the scope (uncalibrated, or `--lens`, or `--recalibrate`).

If nothing to calibrate:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | calibrate | ✅ All calibrated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All active lenses are already calibrated.
Use --recalibrate to re-teach preferences.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [R] Run · [?] /keeper:help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

---

## Step 1: Labelling calibration

If labelling is in scope:

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | calibrate | 🏷️ Labelling
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░ 20% · Labelling preferences...
```

### 1a. Choose header format

Follow the "Progressive calibration" section from `lenses/labelling.md`:

Use AskUserQuestion — present the two Keeper header formats with previews:

- **JSDoc @dossier** — structured JSDoc block with @category, @purpose, @dependencies
- **Tetris well** — visual ASCII box with category and purpose

### 1b. Define categories

Generate default categories based on detected framework (from `.keeperrc.json`).

Pick 5 diverse sample files from the project. For each file, ONE AT A TIME:
- Propose a category
- Use AskUserQuestion: "{filename} — {proposed category}?"
  - **Accept** — keep this category
  - **Change** — let me pick a different category
  - **Add new** — this file needs a new category

### 1c. Save labelling calibration

Update `.keeperrc.json`:
- `tags.headerFormat` → chosen format
- `tags.categories` → refined categories

Update `_keeper/memory.json`:
- `calibration.labelling.calibratedOn` → current date

---

## Step 2: Untangling calibration

If untangling is in scope:

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | calibrate | 🔧 Untangling
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░ 50% · Refactoring style...
```

### 2a. Find complex functions

Scan the codebase for 7 functions above the complexity threshold. Use the complexity tool configured in `.keeperrc.json` (eslint-plugin-sonarjs or claude-fallback).

### 2b. Propose refactoring style

For each function, show a one-line refactoring proposal:
- e.g., "extract guard clause", "split into helper", "replace nested ifs with early returns"

Use AskUserQuestion for each:
- "**{functionName}** (CC: {score}) — {proposal}?"
  - **Approve** — save this style preference
  - **Modify** — suggest a different approach
  - **Skip** — don't refactor this one

### 2c. Save untangling calibration

Update `_keeper/memory.json`:
- `calibration.untangling.stylePreferences[]` → approved preferences
- `calibration.untangling.calibratedOn` → current date

---

## Step 3: Done

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Keeper | calibrate | ✅ Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{For each calibrated lens:}
✅ {lens} — {summary of choices}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [R] Run · [L] Loop · [?] /keeper:help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

1. **Always use AskUserQuestion.** This is an interactive skill — never guess preferences.
2. **One proposal at a time.** Don't batch calibration decisions.
3. **Context-aware.** Read encyclopedia and memory before suggesting — don't ignore what keeper already knows.
4. **Save immediately.** Write calibration results after each lens, not at the end.
5. **Respect --lens scope.** If a specific lens is requested, only calibrate that lens.

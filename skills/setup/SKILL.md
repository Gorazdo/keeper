---
name: setup
description: Bootstrap keeper in your project — detect stack, create config and memory files. Use this skill when the user wants to set up keeper, configure it for a new project, reconfigure an existing setup, or recalibrate keeper settings including nudge behavior.
user-invokable: true
disable-model-invocation: true
---

# Keeper Setup

Arguments: $ARGUMENTS

Accepted arguments:
- `--reconfigure` — re-run setup even if `.keeperrc.json` exists (overwrites config)
- No arguments — default bootstrap

You are bootstrapping keeper for this project. This is a minimal, fast setup — no calibration happens here. Each lens calibrates itself on first use.

Follow the personality and output format from `personality.md`. Every response uses the Keeper Block format.

## HARD RULES

1. **Only write config/memory/encyclopedia files** — do not modify any source code
2. **Use AskUserQuestion** for all user choices — never text-based menus
3. **Show progress bar** throughout — update percentage at each phase transition
4. **Detect, don't assume** — verify test runners, frameworks, etc. from actual project files
5. **Respect existing config** — if `.keeperrc.json` exists, load it and offer to reconfigure

---

## Phase 1: Detect Project (~10%)

Output the Keeper Block header:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v{version} | setup | Phase 1/3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▓░░░░░░░░░░░░░░░░░░░░░░░░ 10% · Detecting project...
```

### 1a. Check for existing config

Read `.keeperrc.json` at project root. If it exists:
- Load and display current config summary
- Use AskUserQuestion: "Keeper is already set up. What would you like to do?"
  - **Reconfigure** — "Re-detect project and update config"
  - **Reset** — "Start fresh — new config and memory"
  - (User can also pick Other)

### 1b. Check for legacy configs (migration)

Check for:
- `.untanglerc.json` — from untangle-with-ralph-loop
- `.dossierrc.json` — from dossier
- `_gary-the-gardener/` — from gary-the-gardener

If any exist, offer migration:
- Use AskUserQuestion: "Found legacy config from {plugin}. Merge settings into keeper?"
  - **Merge** — "Import settings, then remove old files"
  - **Ignore** — "Start fresh, leave old files alone"

If merging, extract relevant settings (test runner, categories, style preferences, etc.) and apply them in Phase 3.

### 1c. Auto-detect project

Detect the following from actual project files:

**Language & framework:**
- Check file extensions in `src/` (or root): `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.rs`, `.java`, `.rb`
- Check for framework markers:
  - React: `package.json` has `react` dep, `src/` has `.tsx` files
  - Next.js: `next.config.*` exists
  - Vue: `vue.config.*` or `package.json` has `vue`
  - Angular: `angular.json` exists
  - Django: `manage.py` exists
  - FastAPI: `package.json` has `fastapi` or `main.py` imports fastapi
  - Express: `package.json` has `express`

**Source globs:** Infer from project structure (e.g., `src/**/*.ts` for TypeScript)

**Exclude globs:** Standard: `node_modules`, `dist`, `build`, `.next`, `coverage`, `*.test.*`, `*.spec.*`, `__tests__`, `.git`, `__pycache__`

**Test runner (for code lenses):**
- Look for `vitest.config.*` → Vitest
- Look for `jest.config.*` → Jest
- Check `package.json` scripts and dependencies
- Look for `pytest.ini`, `pyproject.toml [tool.pytest]` → Pytest
- If ambiguous: ask the user

**Test commands:** Infer from runner:
- Vitest: `npx vitest run`, single: `npx vitest run {file}`, coverage: `npx vitest run --coverage`
- Jest: `npx jest`, single: `npx jest {file}`, coverage: `npx jest --coverage`

**Complexity tool:** Check for `eslint-plugin-sonarjs` in node_modules or package.json. If present, use it. Otherwise, `claude-fallback`.

Show a brief summary of what was detected.

---

## Phase 2: Create Config (~50%)

Update progress:
```
▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░ 50% · Writing config...
```

All 12 lenses are activated by default. Lens filtering happens at run time (`--lens` flag) and deploy time (daemon schedule). Setup does not ask which lenses to use.

Write `.keeperrc.json`:
```json
{
  "version": "1.0",
  "projectName": "{detected project name from package.json name field or directory name}",
  "general": {
    "sourceGlobs": ["{detected}"],
    "excludeGlobs": ["{detected}"],
    "models": {
      "scan": "haiku",
      "tag": "haiku",
      "refactor": "sonnet",
      "hard": "opus"
    }
  },
  "activeLenses": ["untangling", "modernization", "testability", "boundaries", "micro-hygiene", "type-safety", "friction", "error-handling", "labelling", "jsdoc", "markdown", "docs-coverage"],
  "tags": {
    "headerFormat": "jsdoc",
    "categories": ["{detected from stack}"]
  },
  "untangle": {
    "complexityThreshold": 10,
    "coverageThreshold": 80,
    "maxIterations": 15,
    "testRunner": "{detected}",
    "testCommand": "{detected}",
    "testSingleFile": "{detected}",
    "coverageCommand": "{detected}",
    "complexityTool": "{detected or 'claude-fallback'}"
  },
  "schedule": {
    "workingHours": "09:00-18:00",
    "timezone": "UTC"
  },
  "pr": {
    "maxFunctionsPerPr": 5,
    "maxOpenPRs": 3,
    "branchPrefix": "keeper"
  },
  "nudge": {
    "enabled": true,
    "cooldownMinutes": 30,
    "lenses": ["labelling", "micro-hygiene", "jsdoc"]
  }
}
```

### Category detection for `tags.categories`

Seed initial categories by scanning the project's directory structure and file naming patterns:
- **React/Next.js**: Component, Hook, Page, Route, Layout, Context, Provider, Utility, Config, Test, Type
- **Express/Fastify**: Route, Controller, Middleware, Service, Model, Utility, Config, Test, Type
- **Generic Node.js**: Service, Utility, Helper, Config, Test, Type, Constant
- **Fallback** (if stack not recognized): Service, Utility, Config, Test, Type, Helper

Always include at least: Utility, Config, Test, Type. Add stack-specific categories on top. The doer will refine these during labelling calibration on first run.

Write `_keeper/memory.json`:
```json
{
  "version": "1.0",
  "calibration": {
    "labelling": { "calibratedOn": null },
    "untangling": { "calibratedOn": null, "stylePreferences": [] }
  },
  "tags": {
    "taggedFiles": [],
    "categoryPatterns": [],
    "customRules": []
  },
  "refactoring": {
    "patterns": [],
    "gotchas": [],
    "patternRegistry": [],
    "completedFunctions": [],
    "humanReviewRequired": []
  },
  "sessions": {
    "lastRun": null,
    "lastSleep": null,
    "pendingConsolidation": [],
    "openPRs": []
  },
  "summary": ""
}
```

Create `_keeper/` directory with `_keeper/output/supervised/` and `_keeper/output/autonomous/` subdirectories, plus:

`_keeper/encyclopedia/architecture.md`:
```markdown
# Architecture

Project architecture insights. Promoted from short-term memory during sleep consolidation.

<!-- Keeper will populate this file over time -->
```

(Same stub pattern for `patterns.md`, `gotchas.md`, `taxonomy.md`, `conventions.md` — each with appropriate title and description.)

`_keeper/history.md`:
```markdown
# History

Heritage, moments, and project evolution.

## Setup
- {date}: Keeper initialized. {N} lenses active. {language}/{framework} project.
```

`_keeper/briefing.md`:
```markdown
# Morning Briefing

No briefing yet. Run `/keeper:run` to start working, then `/keeper:sleep` to consolidate learnings.
```

---

## Phase 3: Finalize (~90%)

Update progress:
```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░ 90% · Finalizing...
```

### 3a. Nudge configuration

Use AskUserQuestion:
- Question: "Enable nudge mode? Keeper watches your edits and runs quick lens checks on files you touch."
- Options:
  - **Yes (recommended)** — "Nudge every ~30 min using labelling, micro-hygiene, jsdoc lenses"
  - **No** — "Disable nudge — I'll run keeper manually"
  - **Custom** — "Let me configure cooldown and lens selection"

If Custom: ask for cooldown minutes and which lenses to include (from the haiku-tier lenses). Update `nudge` section in `.keeperrc.json`.

After nudge configuration, write `_keeper/nudge.conf` (simple key=value format read by hook scripts):
```
enabled=true
cooldown_minutes=30
extensions={derived from general.sourceGlobs — e.g., ts|tsx|js|jsx|py}
lenses=labelling|micro-hygiene|jsdoc
```

This file avoids JSON parsing in the hook scripts. Regenerate it on `--reconfigure`.

### 3b. PR lifecycle defaults

Use AskUserQuestion:
- Question: "How should keeper handle PRs by default?"
- Options:
  - **Create only (recommended)** — "I'll review and merge myself"
  - **Request review** — "Add a reviewer to each PR"
  - **Full lifecycle** — "Request review + auto-merge when approved and CI passes"

If "Request review" or "Full lifecycle": ask for reviewer username(s) (default: `copilot`).
If "Full lifecycle": ask for merge strategy (`squash`, `merge`, `rebase`).

Save to `.keeperrc.json` `pr` section:
```json
{
  "pr": {
    "maxFunctionsPerPr": 5,
    "maxOpenPRs": 3,
    "branchPrefix": "keeper",
    "reviewers": ["copilot"],
    "autoMerge": "squash"
  }
}
```

These defaults apply when running without a workflow. Workflows can override them.

### 3c. Gitignore

Use AskUserQuestion:
- Question: "Add keeper files to .gitignore?"
- Options:
  - **Config only** — "Commit .keeperrc.json, gitignore _keeper/ (personal learnings)"
  - **All keeper files** — "Gitignore .keeperrc.json and _keeper/"
  - **Commit everything** — "Track all keeper files in git (shared with team)"

Apply choice to `.gitignore` (create if needed, append if exists).

### 3d. Done

Update progress to 100%.

Output the final Keeper Block:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v{version} | setup | ✅ Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{projectName} · {language}/{framework}
12 lenses active (all)
Test runner: {runner}
Nudge: {enabled|disabled}

Files created:
  .keeperrc.json
  _keeper/memory.json
  _keeper/output/supervised/
  _keeper/output/autonomous/
  _keeper/encyclopedia/ (5 articles)
  _keeper/history.md
  _keeper/briefing.md

Next: /keeper:scan to see what needs attention

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↘️ [S] Scan now · [X] Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Each lens will calibrate itself on first use — no upfront calibration needed.

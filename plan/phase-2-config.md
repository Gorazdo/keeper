# Phase 2: Config & Memory Infrastructure

## Status: ⬜ Pending

## Files to Create

- `commands/setup.md` — bootstrap command

## Runtime Files Created by Setup

```
{project}/
├── .keeperrc.json              # Config (procedural memory)
├── .keeper-memory.json         # Short-term memory
└── _keeper/
    ├── encyclopedia/           # Long-term memory (articles)
    │   ├── architecture.md
    │   ├── patterns.md
    │   ├── gotchas.md
    │   ├── taxonomy.md
    │   └── conventions.md
    ├── history.md              # Heritage, moments
    └── briefing.md             # Morning briefing
```

## `.keeperrc.json` Schema

```json
{
  "version": "1.0",
  "projectName": "...",
  "general": {
    "sourceGlobs": ["src/**/*.ts", "src/**/*.tsx"],
    "excludeGlobs": ["node_modules", "dist", "coverage"],
    "models": { "scan": "haiku", "tag": "haiku", "refactor": "sonnet", "hard": "opus" }
  },
  "activeLenses": ["untangling", "testability", "labelling", "error-handling"],
  "tags": {
    "headerFormat": "jsdoc",
    "categories": ["Component", "Utility", "Hook", "Service"]
  },
  "untangle": {
    "complexityThreshold": 10,
    "coverageThreshold": 80,
    "maxIterations": 15,
    "testRunner": "vitest",
    "testCommand": "npx vitest run",
    "complexityTool": "claude-fallback"
  },
  "schedule": {
    "workingHours": "09:00-18:00",
    "timezone": "Europe/Prague"
  },
  "pr": {
    "maxFunctionsPerPr": 5,
    "branchPrefix": "keeper"
  }
}
```

## `.keeper-memory.json` Schema

```json
{
  "version": "1.0",
  "calibration": {
    "labelling": { "calibratedOn": null },
    "untangling": { "calibratedOn": null, "stylePreferences": [] }
  },
  "tags": { "taggedFiles": [], "categoryPatterns": [], "customRules": [] },
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
    "pendingConsolidation": []
  },
  "summary": ""
}
```

## Setup Flow

1. Detect project: language, framework, source globs, test runner
2. Choose active lenses (AskUserQuestion, multi-select from all 12)
3. Create `.keeperrc.json` with detected defaults
4. Create `.keeper-memory.json` with empty sections
5. Create `_keeper/` with encyclopedia stubs, empty history, empty briefing
6. Offer `.gitignore` additions
7. Show progress bar throughout

Migration: if `.untanglerc.json`, `.dossierrc.json`, or `_gary-the-gardener/` exist, offer to merge into keeper config.

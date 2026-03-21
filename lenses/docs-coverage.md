---
name: Documentation Coverage
description: Documentation gaps and drift — missing AGENTS.md, oversized interfaces, stale references
scope: module
type: docs
agent: doer
model: sonnet
spawn: subagent
---

> **Scanner vs Doer responsibility:** The scanner identifies *which* directories/files have documentation coverage issues. The doer creates, updates, or prunes the documentation.

## What this lens detects

Structural documentation gaps and drift between documentation and code. Focuses on the interface layer (AGENTS.md) and documentation directory health.

### Class 1: Missing AGENTS.md

Complex directories that should have an AGENTS.md but don't. AGENTS.md is the AI-readable module contract.

**What to look for:**
Apply the split-candidate rule: a directory warrants its own AGENTS.md if it has:
- ≥3 subdirectories, each containing ≥5 files

Scan all source directories matching source globs. For each directory meeting the split-candidate threshold, check if `AGENTS.md` exists.

**What NOT to flag:**
- `node_modules/`, `dist/`, `build/`, `.next/`, `coverage/`
- Directories with fewer than 3 subdirs or fewer than 5 files per subdir
- The project root (root may use CLAUDE.md instead)

### Class 2: Oversized AGENTS.md

AGENTS.md files that exceed the recommended 150-line limit.

**What to look for:**
- Count lines in each AGENTS.md found in the project
- Flag any exceeding 150 lines
- Note how many lines over the limit

### Class 3: Documentation drift

Claims in documentation files that contradict the actual code.

**What to look for:**
- AGENTS.md references to exports that no longer exist in the module
- AGENTS.md "structure tree" listing files/directories that were deleted or renamed
- README.md claiming features or APIs that don't exist in the code
- Documentation mentioning configuration options that aren't implemented

**How to detect:**
- Read AGENTS.md content
- Extract references to file paths, export names, directory names
- Verify each reference exists using Glob/Grep
- For export references: check if the named export exists in the referenced file

### Class 4: Documentation deserts

Source directories with multiple exported files but zero markdown documentation.

**What to look for:**
- Directories with ≥3 source files that export functions/classes
- No `.md` files in the directory or its parent
- No `AGENTS.md`, no `README.md`, no documentation of any kind

**What NOT to flag:**
- Test directories
- Type/interface-only directories
- Directories already covered by a parent directory's AGENTS.md (check if parent's AGENTS.md mentions this directory)

## Severity rules

- **warning** — documentation drift: AGENTS.md references non-existent exports (Class 3) — actively misleading AI agents
- **warning** — documentation drift: README claims non-existent features (Class 3) — misleading developers
- **suggestion** — missing AGENTS.md on complex directory (Class 1) — AI agents lack module context
- **suggestion** — oversized AGENTS.md (Class 2) — should be compacted
- **suggestion** — documentation desert (Class 4) — no docs at all for a non-trivial module

## Examples

```
CLASS 1: missing AGENTS.md (suggestion)
Scanner flags: "src/api/ has 4 subdirectories (auth/, users/, orders/, products/)
  each with 6+ files — no AGENTS.md"

CLASS 3: documentation drift (warning)
Scanner flags: "AGENTS.md references 'export function validateOrder'
  but src/api/orders/index.ts has no such export"

CLASS 4: documentation desert (suggestion)
Scanner flags: "src/utils/ has 8 exported files, 0 markdown files"
```

---
name: Labelling
description: File categorization with JSDoc or ASCII box headers — unlabeled files, stale headers, ambiguous files
scope: file
type: docs
agent: tagger
model: haiku
spawn: none
---

> **Scanner vs Tagger responsibility:** The scanner identifies *which* files lack or have stale labels. The tagger determines the category and generates the header content.

## What this lens detects

Files that lack structured category headers, have outdated headers, or don't fit into the project's taxonomy. Labels make it faster for both humans and AI to understand what each file does.

### Class 1: Unlabeled files

Source files that have no dossier header at all — no `@dossier` JSDoc block, no `╔` Tetris well.

**What to look for:**
- Read the first 20 lines of each source file
- Check for `@dossier` in a JSDoc comment block
- Check for `╔` or `╚` characters in comment lines (Tetris well format)
- If neither found → unlabeled

**What NOT to flag:**
- Test files, config files, type declaration files — these are excluded by source globs
- Files in `node_modules/`, `dist/`, `build/`, `.next/`
- Generated files (`*.generated.*`, `*.min.*`)

### Class 2: Stale headers

Files where the content has changed since the header was last applied. The header may describe an outdated purpose or incorrect dependencies.

**What to look for:**
- Compare file's current content hash (excluding the header itself) against the hash stored in `_keeper/memory.json` `tags.taggedFiles`
- If path matches but hash differs → stale
- If path is in taggedFiles but file no longer exists → dead entry (flag for memory cleanup)

### Class 3: Ambiguous files

Files that don't clearly fit any category in the current taxonomy. Previously flagged by the tagger as ambiguous.

**What to look for:**
- Check `_keeper/memory.json` for any files previously flagged as ambiguous
- These files were scanned but the tagger couldn't confidently assign a category

## How to detect

### Class 1: Unlabeled
Scan first 20 lines of each source file. Fast — no deep analysis needed.

### Class 2: Stale
Compare content hashes from memory against current file content (excluding header). Hash computation: SHA-256 of file content after stripping any `@dossier` block or `╔...╚` well (including any ❌/⚠️ lines immediately adjacent).

### Class 3: Ambiguous
Read memory entries. No file scanning needed.

## Severity rules

- **warning** — exported/public source file with no label (Class 1) — these are the highest priority
- **suggestion** — stale header (Class 2) — content changed, header may be outdated
- **suggestion** — ambiguous file (Class 3) — needs taxonomy expansion or manual categorization

## Progressive calibration

On first use of the labelling lens (if `calibration.labelling.calibratedOn` is null):

1. **Choose header format** — present Keeper's two formats with examples. AskUserQuestion with 2 options:

   **Option A — JSDoc `@dossier`:**
   ```
   /**
    * @dossier
    * @errors Uncaught promise in fetchUrl
    * @category Service
    * @purpose Centralized URL construction for server-side operations
    * @dependencies ./config, ./utils/path
    * @dependents ./api/router, ./middleware/proxy
    * @warnings Missing input validation
    */
   ```

   **Option B — Tetris well:**
   ```
   // ❌ [Uncaught promise in fetchUrl]
   // ╔═══════════════════════════════════════════════════
   // ║ [Service] [UrlService]
   // ║ Centralized URL construction
   // ╚═══════════════════════════════════════════════════
   // ⚠️ [Missing input validation]
   ```

   Do NOT scan the codebase for existing styles. Always present these two Keeper formats.
2. **Define categories** — generate defaults based on detected framework. Pick 5 diverse sample files, propose category ONE AT A TIME, let user approve/modify/add.
3. **Save** — update `.keeperrc.json` with headerFormat and categories, set calibratedOn date.

Subsequent uses skip calibration.

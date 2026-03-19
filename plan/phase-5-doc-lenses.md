# Phase 5: Doc Lenses

## Status: ⬜ Pending

## Files to Create

- `agents/tagger.md` — file labelling agent (haiku)
- `lenses/labelling.md` — file categorization lens
- `lenses/jsdoc.md` — JSDoc quality lens
- `lenses/markdown.md` — markdown quality lens
- `lenses/docs-coverage.md` — documentation coverage lens

## Tagger Agent

Ported from dossier/agents/tagger.md. Model: haiku.

Handles the labelling lens. Batch file analyzer:
1. Fast-path: check learned category patterns (directory/naming)
2. Read file content, determine category from taxonomy
3. Write one-line purpose (under 80 chars, factual)
4. Extract internal dependencies (up to 5)
5. Generate header string in chosen format (JSDoc or ASCII box)
6. Flag ambiguous files

Output: structured table + per-file header blocks.

## Doc Lenses

### labelling.md
```yaml
---
name: Labelling
description: File categorization with JSDoc or ASCII box headers
scope: file
type: docs
agent: tagger
---
```

Detects:
- Files without any dossier header (`@dossier` or `╔...╝` box)
- Files with stale headers (content hash changed since last tag)
- Files matching no category in taxonomy (ambiguous)

Progressive calibration on first use:
1. Choose header format (JSDoc vs ASCII box) with live examples
2. Generate default taxonomy based on framework
3. Present 5 sample categorizations for approval
4. Save to calibration state

### jsdoc.md
```yaml
---
name: JSDoc
description: JSDoc comment quality, completeness, accuracy
scope: function
type: docs
agent: doer
---
```

Detects:
- Exported functions missing JSDoc entirely
- JSDoc with missing `@param` or `@returns` tags
- JSDoc descriptions that are empty or trivially restating the function name
- `@param` types that contradict TypeScript types
- `@deprecated` without migration guidance

### markdown.md
```yaml
---
name: Markdown
description: Markdown file structure, formatting, content quality
scope: file
type: docs
agent: doer
---
```

Detects:
- README.md missing standard sections (description, install, usage)
- Broken internal links (references to files/headings that don't exist)
- Outdated code examples (reference functions/APIs that no longer exist)
- Empty sections (heading with no content)
- Very long files without table of contents

### docs-coverage.md
```yaml
---
name: Documentation Coverage
description: Documentation gaps, drift, AGENTS.md quality
scope: module
type: docs
agent: doer
---
```

Detects:
- Directories with ≥3 subdirs × ≥5 files but no AGENTS.md
- AGENTS.md exceeding 150 lines
- AGENTS.md referencing exports/files that no longer exist (drift)
- README.md claims contradicting actual code behavior (drift)
- Source directories with zero .md documentation files

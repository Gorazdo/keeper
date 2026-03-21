---
name: Markdown
description: Markdown file structure and content quality — missing sections, broken links, stale examples
scope: file
type: docs
agent: doer
model: sonnet
spawn: none
---

> **Scanner vs Doer responsibility:** The scanner identifies *which* markdown files have structural or content issues. The doer fixes the content.

## What this lens detects

Markdown files that have structural problems, broken references, or outdated content. Healthy markdown files are the primary documentation interface for humans.

### Class 1: Missing standard sections

README.md files that lack expected sections for the project type.

**What to look for:**
- Root `README.md` missing any of: project description (first paragraph), install/setup instructions, usage examples
- Package/library README missing: API reference or link to docs
- `CONTRIBUTING.md` present but missing: how to set up dev environment, how to run tests

**What NOT to flag:**
- Non-README markdown files (these have variable structure)
- README files in subdirectories (different expectations than root)
- Intentionally minimal READMEs (e.g., in a monorepo package with docs elsewhere)

### Class 2: Broken internal links

References to files, headings, or anchors that don't exist.

**What to look for:**
- Markdown links `[text](path)` where the target file doesn't exist on disk
- Heading anchors `[text](#heading)` where no matching heading exists in the file
- Relative links that point outside the repo or to deleted files
- Image references `![alt](path)` where the image doesn't exist

**How to detect:**
- Extract all `[...](...)` patterns from markdown files
- For file links: check if target file exists using Glob
- For heading anchors: check if heading exists in target file (convert heading to anchor format: lowercase, spaces→hyphens, strip special chars)

### Class 3: Stale code examples

Code blocks that reference functions, APIs, or patterns that no longer exist.

**What to look for:**
- Code blocks (` ``` `) that import from paths that don't exist
- Code blocks that call functions not exported from the referenced module
- Code blocks with package versions that are significantly outdated
- CLI command examples that reference scripts not in package.json

**How to detect:**
- Extract code blocks from markdown files
- For import statements in code blocks: verify the imported path exists and exports the referenced names
- For CLI commands: verify scripts exist in package.json

### Class 4: Empty or stub sections

Headings with no meaningful content below them.

**What to look for:**
- Heading followed immediately by another heading (nothing between them)
- Heading followed only by "TODO", "TBD", "Coming soon", or similar placeholder text
- Heading followed only by an empty line and then another heading

### Class 5: Long files without navigation

Markdown files over 200 lines with no table of contents.

**What to look for:**
- File exceeds 200 lines
- No table of contents section (check for a heading containing "Table of Contents", "TOC", "Contents", or a list of heading links near the top)

## Severity rules

- **warning** — broken internal link (Class 2) — actively misleading, readers will hit dead ends
- **warning** — stale code example importing non-existent module (Class 3) — copy-paste will fail
- **suggestion** — missing standard sections in root README (Class 1) — impacts first impressions
- **suggestion** — empty/stub section (Class 4) — incomplete documentation
- **suggestion** — long file without TOC (Class 5) — hard to navigate

## Examples

```markdown
<!-- CLASS 2: broken link (warning) -->
<!-- Scanner flags: "link target docs/API.md does not exist" -->
See the [API documentation](docs/API.md) for details.

<!-- CLASS 4: empty section (suggestion) -->
<!-- Scanner flags: "heading with no content" -->
## Contributing

## License
MIT
```

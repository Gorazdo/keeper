---
name: code-quality
description: Code quality pass — untangle complexity, fix micro-hygiene, improve error handling
cadence: 4h
lenses: [untangling, micro-hygiene, error-handling]
max-open-prs: 3
---

Runs three code-focused lenses every 4 hours. Creates PRs for review
without requesting reviewers or enabling auto-merge — you handle the
review and merge yourself.

Good for: supervised daemon mode where you want keeper finding work
but you stay in control of what gets merged.

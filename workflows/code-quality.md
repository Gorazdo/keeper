---
name: code-quality
description: Code quality pass — untangle complexity, fix micro-hygiene, improve error handling
cadence: 4h
lenses: [untangling, micro-hygiene, error-handling]
max-open-branches: 3
---

Runs three code-focused lenses every 4 hours. Pushes branches for
review — you handle the review and merge yourself.

Good for: supervised daemon mode where you want keeper finding work
but you stay in control of what gets merged.

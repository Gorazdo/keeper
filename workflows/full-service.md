---
name: full-service
description: Full autonomous loop — all lenses, push branches for review
cadence: 4h
lenses: [untangling, modernization, testability, boundaries, micro-hygiene, type-safety, friction, error-handling, labelling, jsdoc, markdown, docs-coverage]
max-open-branches: 3
---

Runs all 12 lenses every 4 hours. Pushes branches for review.

Good for: hands-off daemon mode. Keeper works like a full-time
engineer focused on repository hygiene. You create PRs from the
pushed branches and review in your morning briefing.

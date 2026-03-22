---
name: full-service
description: Full autonomous loop — all lenses, copilot review, auto-merge
cadence: 4h
lenses: [untangling, modernization, testability, boundaries, micro-hygiene, type-safety, friction, error-handling, labelling, jsdoc, markdown, docs-coverage]
reviewers: [copilot]
auto-merge: squash
max-open-prs: 3
---

Runs all 12 lenses every 4 hours. Requests copilot review and
auto-merges (squash) when approved and CI passes.

Good for: hands-off daemon mode. Keeper works like a full-time
engineer focused on repository hygiene. You review merged PRs
in your morning briefing.

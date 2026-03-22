---
name: docs-hygiene
description: Daily docs pass — file labels, JSDoc, docs coverage
cadence: 24h
lenses: [labelling, jsdoc, docs-coverage]
reviewers: [copilot]
max-open-prs: 2
---

Runs documentation lenses once per day. Requests copilot review on
each PR so you get a second opinion before merging.

Good for: keeping docs current without thinking about it. Low risk —
docs changes rarely break anything.

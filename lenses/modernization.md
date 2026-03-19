---
name: Modernization
description: Paradigm-level shifts — imperative → declarative, callbacks → async, stringly-typed → structured
scope: function
type: code
agent: doer
---

> **Scanner vs Doer responsibility:** The scanner detects the *paradigm mismatch* — code written in an older style when the codebase has moved on. The doer decides the specific modern syntax based on the project's environment.

> **Modernization vs Micro-hygiene:** Modernization catches *how you structure logic* (paradigm). Micro-hygiene catches *how you write a single expression* (verbosity, mutability). If the issue is "this loop should be a map" → modernization. If the issue is "this let should be const" → micro-hygiene.

## What this lens detects

Code written in an older paradigm when a more expressive one is available. The scanner identifies **paradigm mismatches** — not specific syntax, but structural patterns that indicate the code was written (or copied) before the codebase adopted a newer style.

### Class 1: Imperative → Declarative

Code that uses step-by-step mutation to produce a result, where a declarative transformation would express the intent more clearly.

**What to look for:**
- Loop that builds an output collection by pushing/accumulating → transformation pattern (map, filter, reduce family)
- Loop with early exit on condition → search pattern (find, some, every family)
- Sequential if/else-if chain mapping input values to output values → lookup pattern
- Manual index tracking across a collection → iterator/generator pattern

**What NOT to flag:**
- Loops with complex control flow (multiple breaks, labeled continues) — the imperative form may be clearer
- Loops performing side effects per iteration (sending requests, writing files) — declarative doesn't help
- Performance-critical hot paths where the imperative form is intentional

### Class 2: Callback → Async control flow

Code that manages asynchronous operations through nesting or chaining, where linear async flow would be clearer.

**What to look for:**
- Promise chains (`.then().then().then()`) — sequential async expressed as a chain
- Nested callbacks (callback inside callback inside callback)
- Manual Promise construction (`new Promise((resolve, reject) => ...)`) wrapping an already-async operation
- Event-emitter patterns used for what is actually a request/response flow

**What NOT to flag:**
- Streams or event-driven patterns that are genuinely event-based (not request/response)
- Single `.then()` for simple fire-and-forget

### Class 3: Stringly-typed → Structured

Code that uses strings, magic numbers, or loosely-typed values where the language offers structured alternatives.

**What to look for:**
- String comparisons used for branching (`if (status === 'active')`) without a union type or enum constraining the values
- Magic numbers without named constants (`if (retries > 3)`, `setTimeout(fn, 86400000)`)
- Object shape passed around without a type/interface defining the contract
- String templates used to build structured data (SQL, HTML, JSON built via concatenation)

**What NOT to flag:**
- String comparisons against values from external APIs (the string is the contract)
- Constants that are self-explanatory in context (`index + 1`, `slice(0, -1)`)

### Class 4: Mixed module systems

Code that mixes or uses legacy module patterns inconsistent with the rest of the codebase.

**What to look for:**
- `require()` in a codebase that predominantly uses `import`
- `module.exports` in a codebase that uses `export`
- Dynamic `require()` where dynamic `import()` is the established pattern
- Barrel files (`index.ts` re-exporting everything) in a codebase that uses direct imports

**Detection approach:** Compare the function's file against the dominant pattern in the codebase. Only flag when the function's file is the outlier, not the norm.

## Severity rules

- **warning** — callback nesting 3+ levels deep (genuinely hard to follow)
- **warning** — mixed module system in a file that also uses the modern form (inconsistent within one file)
- **suggestion** — all other paradigm mismatches

## Examples

```typescript
// CLASS 1: imperative → declarative (suggestion)
// Scanner flags: "imperative collection building — loop pushes to output array"
const activeNames = [];
for (const user of users) {
  if (user.active) {
    activeNames.push(user.name);
  }
}

// CLASS 2: callback → async (suggestion)
// Scanner flags: "promise chain — 3 sequential .then() calls"
function loadUser(id) {
  return fetch(`/api/users/${id}`)
    .then(res => res.json())
    .then(data => normalize(data))
    .then(user => enrichWithPrefs(user))
    .catch(err => handleError(err));
}

// CLASS 3: stringly-typed → structured (suggestion)
// Scanner flags: "string comparison branching without type constraint"
function getPrice(tier) {
  if (tier === 'basic') return 10;
  if (tier === 'pro') return 25;
  if (tier === 'enterprise') return 100;
  return 0;
}
// No type constrains what 'tier' can be — a typo ('basik') silently returns 0.
```

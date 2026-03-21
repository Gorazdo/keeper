---
name: Testability
description: Why is this function hard to test — untested, no seams, logic tangled with effects
scope: function
type: code
agent: doer
model: sonnet
spawn: subagent
---

> **Scanner vs Doer responsibility:** The scanner identifies *why* a function is hard to test. The doer decides *how* to introduce seams or separate concerns.

## What this lens detects

Functions that are untested or structurally resistant to testing. Not "missing tests" as a TODO — but architectural reasons that make writing tests painful.

### Class 1: Untested

No test file references this function. The simplest signal — if nobody tests it, it's a risk.

**What to look for:**
- Grep the function name across all test files (`*.test.*`, `*.spec.*`, `__tests__/*`)
- Zero matches → flag

**Caveat:** Functions may be tested indirectly (called by a tested function). This heuristic catches the common case — exported functions with no test mentions are the highest risk.

### Class 2: No seams

The function depends on external resources or non-deterministic inputs, but offers no way to substitute them during testing. There's no injection point — you'd have to monkey-patch or mock at the module level.

**What to look for:**
- Function calls methods on module-level singletons (a client, a connection, a cache) that were not passed in as parameters
- Function constructs its own service objects internally (`new SomeClient(...)`)
- Function reads environment directly (`process.env.*`) rather than receiving config
- Function calls time/random sources directly (`Date.now()`, `new Date()`, `Math.random()`)
- Function accesses global mutable state (`globalThis.*`, `window.*`, module-level `let` variables)

**The test:** Could you call this function in a test file with only its declared parameters and get a deterministic result? If no → no seams.

### Class 3: Logic tangled with effects

The function contains business rules AND side effects in the same body, interleaved. Even if you could mock the side effects, the test would be fragile because it must assert on mock call order rather than return values.

**What to look for:**
- Conditional logic (`if`, `switch`, ternary) where **different branches trigger different side effects** (one branch writes to DB, another sends an email, another calls an API)
- Business rule evaluation (comparisons, filtering, accumulation) **between** side-effect calls — the logic can't be extracted and tested independently
- Early returns that skip side effects — the control flow determines which effects happen

**The test:** Could you extract the business logic into a pure function that returns a decision, and have a separate function that acts on that decision? If the two are tangled → flag.

**What NOT to flag:**
- Functions that are pure orchestration (call A, then B, then C with no branching) — these are just glue, not tangled
- Functions that do one side effect at the end after all logic is resolved — the logic is separable

## How to detect

### Class 1: Untested
One grep per function name across test files. Fast.

### Class 2: No seams
Scan the function body for **effect markers** — calls to things that aren't parameters or local variables:
- Any method call on an identifier that's not a parameter and not declared locally (e.g., `db.query()` where `db` is a module import)
- `new` expressions for non-trivial types (skip `new Error`, `new Map`, `new Set`, `new Date` — flag `new XyzClient`, `new XyzService`)
- Direct reads of `process.env`, `Date.now()`, `Math.random()`, `globalThis`

### Class 3: Logic tangled with effects
Look for both in the same function body:
1. **Conditional logic** — `if`, `switch`, ternary, `&&`/`||` chains
2. **Effect markers** — same as Class 2, but specifically appearing inside or between conditional branches

Flag when effect markers appear **inside conditional branches** (not just at the top or bottom of the function).

## Severity rules

- **warning** — exported function, untested (Class 1), AND has conditional logic (not a trivial passthrough)
- **warning** — logic tangled with effects (Class 3) — fragile to test by nature
- **suggestion** — no seams (Class 2) — testable with module mocking, but friction
- **suggestion** — unexported untested function (Class 1) — lower risk

## Examples

```typescript
// CLASS 3: logic tangled with effects (warning)
// Scanner flags: "conditional branches trigger different side effects"
async function generateReport(params: ReportParams) {
  const rows = await dataWarehouse.query(params.sql);
  if (rows.length === 0) {                                    // branch 1
    logger.warn('Empty report', { params });                  //   → effect: log
    return { status: 'empty', url: null };
  }
  const formatted = rows.map(r => formatRow(r, params.locale));
  if (formatted.length > 10_000) {                            // branch 2
    const file = await csvWriter.write(formatted);            //   → effect: file write
    const url = await s3.upload(file);                        //   → effect: cloud upload
    return { status: 'uploaded', url };
  }
  // branch 3 (default)
  await emailClient.send(params.recipient, formatted);        // → effect: email
  return { status: 'emailed', url: null };
}
// Three branches, each with different effects. Testing any branch
// requires mocking everything and asserting call order.
// The size-check logic and formatting could be pure functions.

// CLASS 2: no seams (suggestion)
// Scanner flags: "module-level singleton used without injection"
function sendNotification(userId: string, message: string) {
  const client = new SlackClient(process.env.SLACK_TOKEN);
  return client.postMessage(userId, message);
}
// Can't call this in a test without SlackClient hitting the network.
// No parameter to substitute a fake client.
```

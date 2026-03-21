---
name: Error Handling
description: Swallowed errors, inconsistent error strategies, missing error paths
scope: function+module
type: code
agent: doer
model: sonnet
spawn: subagent
---

> **Scanner vs Doer responsibility:** The scanner flags *where* error handling is absent, silent, or inconsistent. The doer decides the appropriate strategy (throw, Result type, error boundary, etc.) based on the codebase's conventions.

## What this lens detects

Places where errors are silently lost, handled inconsistently, or not handled at all. These are the bugs that don't crash — they silently produce wrong results, leave systems in broken state, or make debugging impossible.

### Class 1: Swallowed errors

An error is caught but effectively discarded. The catch block doesn't rethrow, doesn't return an error value, and doesn't propagate the failure in any meaningful way. The caller has no idea something went wrong.

**What to look for:**
- Empty catch blocks: `catch (e) { }`
- Catch blocks that only log: `catch (e) { console.log(e) }` or `console.error(e)` — the error is logged but the function continues or returns a default as if nothing happened
- Catch blocks that return a generic success value: `catch (e) { return null }` or `catch (e) { return [] }` without the caller knowing this means "failed"
- `.catch(() => {})` on promises — fire-and-forget error suppression

**What NOT to flag:**
- Catch blocks that log AND rethrow or return a typed error value — that's instrumentation, not swallowing
- Catch blocks in top-level error boundaries (e.g., Express error middleware, React error boundaries) — those are supposed to be the final stop
- Intentional fallbacks where the catch returns a clearly-documented default (e.g., cache miss falling back to fetch)

### Class 2: Inconsistent error strategy

The same codebase uses multiple incompatible patterns for communicating failure. Functions at the same abstraction level handle errors differently — some throw, some return null, some return `{ ok, error }` objects. Callers must guess which pattern each function uses.

**What to look for:**
- Within the same directory or module: some functions throw on failure, others return `null`/`undefined`, others return result objects
- A function that throws for some error cases and returns null for others — mixed strategy within one function
- Error types that aren't used consistently — some functions throw `Error`, some throw string literals, some throw custom error classes, some throw plain objects

**How to detect:**
Scan exported functions in each module/directory and classify their error communication:
- **Throws** — function has `throw` statements
- **Returns null/undefined** — function returns `null` or `undefined` on error paths
- **Returns result** — function returns `{ ok, error }` or `{ success, ... }` shaped objects
- **Returns empty** — function returns `[]` or `{}` on error paths

**Flag the module** when 2+ incompatible strategies coexist among its exported functions.

### Class 3: Missing error paths

Async operations or fallible calls with no error handling at all. The error would propagate as an unhandled rejection or uncaught exception — not because someone decided to let it propagate, but because nobody thought about it.

**What to look for:**
- `await` calls inside a function with no `try/catch` wrapping — AND the function doesn't propagate by design (it's not `async function` all the way up to a handler)
- Promise chains with no `.catch()` — `.then().then()` without terminal error handling
- Calls to functions known to throw (by convention: `JSON.parse`, `new URL()`, `parseInt` with no NaN check) without any guard

**What NOT to flag:**
- `await` in functions that deliberately let errors propagate to a caller that handles them (e.g., service functions called by a route handler with try/catch)
- Top-level `async` functions in frameworks that catch automatically (Next.js server actions, Express async handlers with error middleware)
- Simple `await` in test files

**The test:** If this `await` rejects, does the error reach a handler? If you can't trace a catch within 1-2 levels up, flag it.

## Severity rules

- **warning** — swallowed error in non-trivial function (catch block eats the error, caller can't tell)
- **warning** — missing error path on external I/O (network, database, filesystem) — these fail in production
- **suggestion** — inconsistent error strategy within a module (design smell, causes caller confusion)
- **suggestion** — missing error path on internal calls (less likely to fail, but still unhandled)

## Examples

```typescript
// CLASS 1: swallowed error (warning)
// Scanner flags: "catch block logs but doesn't propagate — caller can't tell this failed"
async function loadConfig(path: string) {
  try {
    const raw = await fs.readFile(path, 'utf-8');
    return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load config', e);
    return {};  // ← caller gets empty object, thinks config has no overrides
  }
}
// If the file is corrupt or missing, the app silently runs with defaults.
// Nobody gets alerted. The bug is invisible.

// CLASS 2: inconsistent strategy (suggestion)
// Scanner flags: "module uses 2 incompatible error strategies — throw and return-null"
// src/services/payment.ts:
export function parseAmount(input: string): number {
  const n = Number(input);
  if (isNaN(n)) throw new ValidationError('Invalid amount');  // ← throws
  return n;
}

export function parseCurrency(input: string): string | null {
  const match = input.match(/^[A-Z]{3}$/);
  if (!match) return null;  // ← returns null
  return match[0];
}
// Callers of parseAmount need try/catch. Callers of parseCurrency need null checks.
// Same module, same kind of operation, different error contracts.

// CLASS 3: missing error path (warning)
// Scanner flags: "await on external call with no error handling — unhandled if it rejects"
async function sendNotifications(users: User[]) {
  for (const user of users) {
    const template = await renderTemplate(user.locale);  // ← no try/catch
    await emailClient.send(user.email, template);        // ← no try/catch
  }
}
// If sending fails on user 5 of 20, users 6-20 never get notified.
// The partial send leaves the system in an inconsistent state.
```

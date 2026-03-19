---
name: Micro-hygiene
description: Verbose → concise, mutable → immutable — small moves that compound
scope: function
type: code
agent: doer
---

> **Scanner vs Doer responsibility:** The scanner detects the *class of issue* (e.g., "manual null-check chain"). The doer decides *how to fix it* based on the project's target environment (TS target, bundler, available syntax). The scanner does not need to know what syntax features are available — it just flags the pattern.

## What this lens detects

Small code hygiene issues that individually seem trivial but compound across a codebase. Each is a quick fix. The lens works in **classes of transformation**, not specific syntax — what's applicable depends on the project's target environment (determined by the doer at fix time).

### Class 1: Unnecessary mutability

Code that uses mutable bindings or mutating operations where immutable alternatives exist.

**What to look for:**
- `let` declarations that are never reassigned → `const`
- Array mutation (`push`, `splice`, `sort` on shared arrays) → immutable alternatives (spread, `toSorted`)
- Object mutation (`delete`, `Object.assign` to existing object) → spread, destructuring with rest

**Do NOT flag:**
- `let` in `for` loop headers
- Mutation of a local variable that doesn't escape the function scope and is clearly accumulating (performance-reasonable)

### Class 2: Manual work the language can do

Code that manually implements something the language has a built-in mechanism for. The scanner flags the **pattern** — the doer decides the appropriate fix based on the project's environment.

**What to look for:**
- Manual null/undefined check chains (`x && x.y && x.y.z`)
- Manual default value assignment with `||` that conflates `0`/`""` with missing
- `for` loop that accumulates into an output array (map/filter/reduce pattern)
- Manual resource cleanup in `try/finally`

### Class 3: Redundant verbosity

Code that says in many lines what could be said in fewer, regardless of language version.

**What to look for:**
- `if (condition) return true; else return false;` → `return condition`
- `if (condition) { x = a } else { x = b }` → `x = condition ? a : b` (only for simple cases)
- Unnecessary `else` after early return — `if (x) return y; else { ... }` → `if (x) return y; ...`
- Unnecessary temp variable — assigned once, used once, on the very next line
- `condition ? true : false` → `Boolean(condition)` or just `condition`

**Do NOT flag:**
- Temp variables that add meaningful naming (self-documenting code)
- Verbose forms that are genuinely more readable in context

### Class 4: Dead patterns

Code that handles cases that can't happen or does work that has no effect.

**What to look for:**
- Catch blocks that only rethrow: `catch (e) { throw e; }`
- Conditions that are always true/false given the surrounding code
- Assignments to variables that are never read after
- `return undefined` at the end of a void function
- Empty blocks: `if (condition) { }`, `else { }`

## Severity rules

- **suggestion** — all patterns in this lens (low-risk, quick fixes)
- Exception: **warning** for nested ternaries (genuinely hard to read, any environment)

## Examples

```typescript
// CLASS 1: unnecessary mutability (suggestion)
let user = await fetchUser(id);  // never reassigned
console.log(user.name);
// → const user = ...

// CLASS 2: manual null-check chain (suggestion)
const city = user && user.address && user.address.city;
// Scanner flags: "manual null-check chain". Doer picks the fix syntax.

// CLASS 3: redundant verbosity (suggestion)
if (items.length > 0) {
  return true;
} else {
  return false;
}
// → return items.length > 0;

// CLASS 4: dead pattern (suggestion)
try {
  await saveUser(user);
} catch (e) {
  throw e;  // catch does nothing
}
// → just await saveUser(user);
```

---
name: JSDoc
description: JSDoc comment quality — missing, incomplete, or inaccurate JSDoc on exported functions
scope: function
type: docs
agent: doer
---

> **Scanner vs Doer responsibility:** The scanner identifies *which* exported functions have missing or poor JSDoc. The doer writes or improves the JSDoc comments.

## What this lens detects

Exported functions that lack JSDoc comments or have incomplete/inaccurate ones. Good JSDoc improves IDE experience, documentation generation, and AI comprehension.

### Class 1: Missing JSDoc

Exported function has no JSDoc comment block immediately above it.

**What to look for:**
- Identify all exported functions (export function, export const, export default, module.exports)
- Check if a `/** ... */` JSDoc block exists on the lines immediately preceding the function declaration
- No JSDoc at all → flag

**What NOT to flag:**
- Non-exported (private) functions — these are internal implementation details
- Re-exports (`export { foo } from './bar'`) — these are pass-throughs
- Type exports (`export type`, `export interface`) — these are self-documenting
- Functions shorter than 3 lines — trivial

### Class 2: Incomplete JSDoc

JSDoc exists but is missing required tags for the function's signature.

**What to look for:**
- Function has parameters but JSDoc has no `@param` tags
- Function returns a non-void value but JSDoc has no `@returns` tag
- `@param` tags exist but don't match actual parameter names
- `@param` count doesn't match actual parameter count

### Class 3: Low-quality JSDoc

JSDoc exists with tags but the descriptions are unhelpful.

**What to look for:**
- Description is empty or whitespace-only
- Description trivially restates the function name: e.g., `/** Gets the user */` on `function getUser()`
- `@param` descriptions are just the parameter name repeated: `@param id the id`
- `@returns` description is just the return type: `@returns {string} string`
- `@param` types contradict TypeScript types (when both exist)

### Class 4: Stale JSDoc

JSDoc references things that no longer exist or are incorrect.

**What to look for:**
- `@param` tags for parameters that were removed
- `@throws` referencing error types not used in the function body
- `@see` or `@link` references to functions/files that don't exist
- `@deprecated` without migration guidance (what to use instead)

## How to detect

### Class 1 & 2: Missing and Incomplete
Read exported function signatures + preceding lines. Fast — structural check only.

### Class 3: Low-quality
Read JSDoc content. Compare description against function name (simple string similarity — if the description is just the function name with spaces, it's low-quality).

### Class 4: Stale
Cross-reference JSDoc tags against actual function signature and codebase. Slightly slower — requires reading function body and potentially grepping for referenced entities.

## Severity rules

- **warning** — exported function with 3+ parameters and no JSDoc at all (Class 1) — callers need documentation
- **warning** — `@param` types contradicting TypeScript types (Class 3) — actively misleading
- **suggestion** — exported function with no JSDoc but simple signature (Class 1)
- **suggestion** — incomplete JSDoc missing `@param` or `@returns` (Class 2)
- **suggestion** — trivial/restating description (Class 3)
- **suggestion** — stale references (Class 4)

## Examples

```typescript
// CLASS 1: missing JSDoc (warning — 3 params, exported)
// Scanner flags: "exported function with 3 params, no JSDoc"
export async function createOrder(
  userId: string,
  items: CartItem[],
  paymentMethod: PaymentInfo
): Promise<Order> {
  // ...
}

// CLASS 2: incomplete JSDoc (suggestion)
// Scanner flags: "JSDoc missing @param for 'options'"
/**
 * Fetches user profile data from the API.
 * @param userId - The user's unique identifier
 * @returns The user profile object
 */
export function fetchProfile(userId: string, options?: FetchOptions) {
  // ...
}

// CLASS 3: low-quality JSDoc (suggestion)
// Scanner flags: "description restates function name"
/**
 * Gets the user.
 * @param id - the id
 * @returns user
 */
export function getUser(id: string): User {
  // ...
}
```

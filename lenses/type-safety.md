---
name: Type Safety
description: Build-time type quality — type holes, unvalidated boundaries, opaque contracts, type drift
scope: function+module
type: code
agent: doer
model: sonnet
spawn: team
---

> **Unique lens:** This lens does not touch runtime code. It analyzes the **type graph** — how type information flows through the codebase, where it breaks, and where annotations lie about what's actually there. Because types are scattered across files, this lens is allowed to follow imports, read type definition files, and trace type chains more than other lenses.

## What this lens detects

Places where TypeScript's type system is weakened, bypassed, or lying — creating false confidence that hides runtime errors.

### Class 1: Type holes

Explicit breaks in type safety where someone told the compiler to stop checking. These are symptoms — the real question is *why* the hole was needed.

**What to look for:**
- `any` in annotations or parameters — the compiler gives up entirely
- `as` assertions — the developer overrides what the compiler inferred
- `as unknown as X` — double assertion, the compiler actively disagreed
- `!` non-null assertions — the developer promises non-null without proof
- `@ts-ignore` / `@ts-expect-error` — suppressing a type error

**When scanning:** Don't just count occurrences. Note *where* in the type flow the hole appears — a type hole at a module boundary (exported function parameter, return type) is far more damaging than one in a local variable.

**Do NOT flag:**
- `as const` — safe, encouraged
- `any` in `.d.ts` declaration files — often necessary
- `catch (e: unknown)` — correct pattern
- Intentionally suppressed with eslint-disable + clear comment explaining why

### Class 2: Unvalidated boundaries

External data enters the system — from APIs, user input, environment, JSON parsing, URL params — and gets a type annotation without runtime validation. The type says `User` but the data could be anything.

**What to look for:**
- `JSON.parse()` result assigned to a typed variable without validation (e.g., `const data: Config = JSON.parse(raw)`)
- API response typed via assertion (`response.data as User`) or generic (`fetch<User>(...)`) without schema validation
- `process.env.X` used as a specific type without checking it exists
- `localStorage.getItem()` / `URLSearchParams.get()` result cast to a specific type
- Function parameters that accept external input typed as a domain type without a validation step

**The test:** Is there a runtime check (Zod, io-ts, ajv, manual validation, type guard) between the external source and the typed variable? If no → the type is a lie.

**When scanning:** Follow the data path one step — where does the typed value come from? Read the import or calling context if needed to determine if it's external.

### Class 3: Opaque contracts

Exported functions where consumers cannot understand the type contract without reading the implementation. The public API doesn't communicate enough through types alone.

**What to look for:**
- Exported functions without explicit return type annotations (consumers see inferred types, which break silently on implementation changes)
- Functions returning `Promise<any>` or `any` — consumers inherit the hole
- Functions with overloads where the implementation signature is looser than the overload signatures
- Generic functions where the type parameter is unconstrained (`<T>` instead of `<T extends SomeBase>`) — consumers don't know what's valid

**When scanning:** Focus on exported/public functions. Internal functions with inferred types are fine — the compiler checks them locally.

### Class 4: Type drift

The same real-world concept has multiple type representations that have drifted apart. A `User` in the API layer has different fields than `User` in the DB layer, and somewhere a mapping silently drops or misnames a field.

**What to look for:**
- Multiple interfaces/types with the same base name in different files (e.g., `User`, `UserDTO`, `UserResponse`, `DBUser`) — read them and compare shapes
- Mapping functions between types that use `as` assertions or `any` to bridge the gap (the types don't actually match)
- Functions that accept one type variant and return another without explicit mapping

**When scanning:** This requires reading type definitions across files. Grep for the concept name (e.g., `interface.*User`, `type.*User`) across the codebase, then read and compare the shapes. Flag when:
- Two types share a base name but differ in more than 2 fields
- A mapping between them uses type assertions

## How to detect

### General approach

Unlike other lenses that scan function bodies, this lens should:
1. **Scan function signatures first** — parameters, return types, generics
2. **Follow type imports** — read the type definition to understand what it actually is
3. **Check boundaries** — is this function at a system boundary (API handler, event listener, CLI entry point)?
4. **Compare related types** — grep for similar type names across the codebase

### Class 1: Type holes
Grep for patterns: `: any`, `as `, `as unknown`, `! .`, `!.`, `@ts-ignore`, `@ts-expect-error`. Note whether they appear in exported signatures (warning) or local code (suggestion).

### Class 2: Unvalidated boundaries
Find system boundary functions (API route handlers, event listeners, CLI handlers). Check if external data gets a type without passing through validation (look for Zod, io-ts, ajv, or manual type guard between the source and the typed variable).

### Class 3: Opaque contracts
Find exported functions. Check for explicit return type annotations. Flag when missing on functions with >5 lines of body.

### Class 4: Type drift
Grep for `interface\s+\w*ConceptName` and `type\s+\w*ConceptName` across the codebase for common domain concepts. Read and compare the shapes. This is the most exploratory detection — only worth doing for concepts that appear in 3+ files.

## Severity rules

- **warning** — type hole at module boundary (exported `any` parameter, `as unknown as X`)
- **warning** — unvalidated boundary on external data (API response, JSON.parse without validation)
- **suggestion** — type hole in local code
- **suggestion** — opaque contract (missing return type on export)
- **suggestion** — type drift detected (same concept, different shapes)

## Examples

```typescript
// CLASS 1: type hole at boundary (warning)
// Scanner flags: "exported function parameter typed as any"
export function processData(input: any): Result {
  // Every caller loses type safety. Why was 'any' needed?
  // → Often means the input shape varies — solution is a union type or generic.
}

// CLASS 2: unvalidated boundary (warning)
// Scanner flags: "API response typed without runtime validation"
async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return data as User;  // ← the API could return anything
}
// No Zod schema, no type guard, no validation.
// If the API changes shape, this silently returns garbage typed as User.

// CLASS 3: opaque contract (suggestion)
// Scanner flags: "exported function without return type annotation"
export async function buildSearchQuery(filters: SearchFilters, options: QueryOptions) {
  // ... 30 lines of logic
  // Callers see an inferred type. If implementation changes, their code
  // breaks silently — the compiler doesn't know the return type was part
  // of the public contract.
}

// CLASS 4: type drift (suggestion)
// Scanner flags: "User concept has 3 type variants with different shapes"
// src/api/types.ts:    interface UserResponse { id: string; name: string; email: string }
// src/db/models.ts:    interface UserRow { user_id: number; full_name: string; email: string }
// src/domain/user.ts:  interface User { id: string; displayName: string; email: string }
// Three representations of "User" — id types differ, name fields differ.
// Mapping between them likely involves assertions or silent field drops.
```

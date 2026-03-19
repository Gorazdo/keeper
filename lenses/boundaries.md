---
name: Boundaries
description: Clear separation of interface and implementation — shallow, leaky, or blurred boundaries
scope: function+module
type: code
agent: doer
---

## What this lens detects

The core idea: every function or module has a boundary between **interface** (what callers see) and **implementation** (what's hidden inside). Good code draws that boundary clearly — the interface is simple, the implementation hides the complexity. This lens finds places where that boundary is missing, misplaced, or not earning its keep.

Three failure modes:

### 1. Shallow boundary — interface ≈ implementation

The abstraction exists but doesn't simplify anything. Callers pass in almost as much information as the function uses internally. Reading the interface doesn't save you from reading the implementation.

Signs:
- Many parameters, especially config/options objects, relative to a small body
- Return type is nearly as complex as the input type (just reshuffling)
- Wrapper functions that add a thin layer over one call

### 2. Leaky boundary — implementation details escape

The boundary exists on paper but callers must understand the internals to use the function correctly. The interface promises encapsulation but doesn't deliver.

Signs:
- Parameters named after internal concepts (`retryCount`, `_internal`, `rawQuery`, `bypassCache`)
- Return values that expose internal representations (raw DB rows, internal error codes)
- Comments/JSDoc warning callers about internal behavior ("must call after X", "don't pass Y when Z")
- Callers that always peek at implementation before calling (visible in usage patterns)

### 3. Blurred boundary — interface and implementation mixed in one function

No clear separation at all. A single function both orchestrates ("what to do") and implements ("how to do it") at different levels of detail. The reader can't skim — they must read every line to find the intent buried in the details.

Signs:
- High-level domain calls mixed with low-level operations (string manipulation, manual object construction)
- I/O calls (DB, HTTP, fs) interleaved with business logic branching
- Framework-specific code (React hooks, Express middleware) mixed with pure logic
- Distinct "phases" within one function (setup → process → cleanup → format → return)

## How to detect

### Shallow boundary

Compare **interface weight** to **implementation depth**:

Interface weight:
- +1 per parameter
- +2 per parameter with a complex type (object, union, generic)
- +3 per config/options object parameter
- +1 per distinct return type in a union return

Implementation depth:
- Count non-blank, non-comment lines in function body

**Flag when:** interface weight ≥ (implementation LOC / 3)

### Leaky boundary

Flag when a function:
- Accepts parameters named like internal concepts (check for: `raw`, `internal`, `bypass`, `retry`, `force`, `_` prefix)
- Returns raw internal types without mapping to a domain type
- Has JSDoc/comments that describe internal behavior rather than the contract
- Requires callers to handle implementation-specific error types or codes

### Blurred boundary

In a single function body, detect both:
1. **High-level calls** — calls to other domain functions, service methods
2. **Low-level operations** — string manipulation, array construction, manual object building, Math operations, regex

**Flag when** both appear in the same function and are interleaved (not cleanly separated into a "prep" section and a "call" section).

Also flag functions with:
- 3+ distinct phases (blocks separated by blank lines or section comments)
- References to 3+ different domains or data structures
- >60 lines with low cognitive complexity (sequential, does many things simply)

## Severity rules

- **warning** — shallow boundary on exported function (callers pay the interface cost with no encapsulation benefit)
- **warning** — blurred boundary in function >60 lines (too much to read, no separation to guide the eye)
- **suggestion** — leaky boundary (still works, but callers carry hidden assumptions)
- **suggestion** — blurred boundary in shorter functions (mild, but worth noting)

## Examples

```typescript
// FLAGGED: shallow boundary — complex interface, trivial body
function createUser(
  name: string,
  email: string,
  role: UserRole,
  options: { sendWelcome: boolean; defaultTeam: string; locale: string }
): User {
  return { name, email, role, ...options, id: generateId() };
}
// Interface weight: ~8. Body: 1 line. The abstraction adds nothing —
// callers already know everything about what happens inside.

// FLAGGED: leaky boundary — internal concepts in interface
async function queryUsers(
  rawSQL: string,           // ← caller must know SQL dialect
  retryCount: number,       // ← caller must know about retry internals
  bypassCache: boolean      // ← caller must know there's a cache
): Promise<DatabaseRow[]> { // ← returns raw DB representation
  // ...
}
// The interface promises "query users" but requires knowing about
// SQL, retries, caching, and DB row shape.

// FLAGGED: blurred boundary — orchestration mixed with implementation
async function syncAnalytics(events: RawEvent[]) {
  // Orchestration level
  const validated = filterValidEvents(events);
  const enriched = await enrichWithUserData(validated);

  // Drops into implementation detail
  const payload = enriched.map(e => ({
    event_name: e.type.toLowerCase().replace(/\s+/g, '_'),
    timestamp: Math.floor(e.createdAt.getTime() / 1000),
    properties: Object.fromEntries(
      Object.entries(e.metadata).filter(([_, v]) => v != null)
    ),
  }));

  // Back to orchestration
  await analyticsClient.batchUpload(payload);
  await updateSyncCursor(enriched.at(-1)?.id);
}
// The payload-mapping block is implementation detail that belongs behind
// a boundary (e.g., toAnalyticsPayload(enriched)). The reader has to parse
// every line to understand the sync flow.
```

---
name: Friction
description: Structural friction — scattered concepts, test deserts, navigation cost
scope: module
type: code
agent: doer
model: sonnet
spawn: subagent
---

## What this lens detects

"The friction you encounter IS the signal."

This lens detects structural friction — places where the codebase fights the developer trying to understand or change it. Unlike function-scoped lenses, this one looks at **how knowledge is distributed across files and directories**.

Two signals:

### 1. Scattered concepts

Understanding one concept requires bouncing between many small files across multiple directories. The knowledge isn't co-located — to understand "how orders work" you must open 6+ files in 4+ folders.

Signs:
- An exported function/class is imported by files across 3+ different directories
- A single file imports from 5+ different directories to assemble one operation
- A concept (identifiable by naming: `order`, `auth`, `payment`) appears in functions spread across 4+ directories with no shared parent

### 2. Test deserts

Entire directories of source code with no test files nearby. Not because the code is trivial — because the architecture makes testing painful or nobody drew the line.

Signs:
- A directory contains source files with exported functions but zero test files in the same directory or a sibling `__tests__/` directory
- Exported functions in the directory have zero references in any test file across the codebase

## How to detect

### Scattered concepts

For each source file being scanned:
1. Read its `import` statements — count how many **distinct directories** it imports from
2. **Flag the file** when it imports from 5+ distinct directories

Then, for each exported function in flagged files:
1. Grep for the function name across all source files (one grep call)
2. Count distinct directories where it appears
3. **Flag the function** when it's referenced from 3+ directories outside its own

This is fast — one grep per exported function in files that already look scattered.

### Test deserts

One-pass detection across the whole project:
1. Glob all directories that contain source files matching `sourceGlobs`
2. For each directory, glob for test files (`*.test.*`, `*.spec.*`) in same dir or `__tests__/` child
3. **Flag the directory** when: zero test files found nearby AND the directory contains 2+ exported functions

Then attach the finding to the most prominent exported function in that directory (highest line count or first export).

## Severity rules

- **warning** — test desert with 3+ exported functions (significant untested surface area)
- **suggestion** — test desert with 2 exported functions
- **suggestion** — scattered concept (navigation friction, not directly risky)

## Examples

### Scattered concept
```
src/checkout/processOrder.ts imports from:
  src/models/        (Order, User types)
  src/services/      (PaymentService)
  src/utils/         (formatCurrency, validateAddress)
  src/config/        (SHIPPING_RATES)
  src/middleware/     (withAuth)
  src/integrations/  (StripeClient)
→ 6 directories. To understand processOrder, you must navigate all of them.

And processOrder itself is referenced from:
  src/api/routes/orders.ts
  src/workers/orderProcessor.ts
  src/webhooks/stripeHandler.ts
→ 3 directories reference it. Knowledge is scattered.
```

### Test desert
```
src/integrations/
  stripe.ts          — 4 exported functions
  sendgrid.ts        — 3 exported functions
  twilio.ts          — 2 exported functions
  (no test files anywhere nearby)
→ 9 exported functions, 0 tests. Test desert.
```

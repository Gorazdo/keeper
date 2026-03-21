---
name: Untangling
description: Control flow complexity — deep nesting, tangled branching, boolean chains
scope: function
type: code
agent: doer
model: sonnet
spawn: none
---

## What this lens detects

Functions where the control flow is hard to follow. The reader loses track of where they are — which conditions are active, which branch they're in, what's true at this point in the code. This is the core "tangled" signal.

### Class 1: Deep nesting

Each nesting level adds a condition the reader must hold in mind. At depth 4+, most readers lose context — they can't remember what's true at the deepest level without scrolling back up.

**What to look for:**
- `if` inside `for` inside `if` inside `try/catch` — stacking control structures
- Callbacks or closures that add invisible nesting levels
- Nesting that could be flattened with guard clauses / early returns but isn't

### Class 2: Tangled branching

Many paths through the function. Hard to verify that all cases are handled, hard to reason about what happens on a specific path without tracing every branch.

**What to look for:**
- `if / else if / else if / else` chains with 4+ branches
- `switch` with many cases, especially with nested logic inside cases (not just return-per-case — that's a lookup, flagged by modernization lens)
- Branches that fall through or share code in non-obvious ways
- Nested conditionals where the inner condition depends on the outer one — creates implicit path combinations

### Class 3: Boolean chain complexity

Complex boolean expressions where the reader must mentally evaluate `&&` / `||` combinations to understand when the branch is taken.

**What to look for:**
- Mixed `&&` and `||` in the same expression without parentheses clarifying precedence
- Boolean expressions with 3+ clauses (e.g., `a && b || c && d`)
- Negated complex conditions (`!( a && b || c )`)
- Conditions that combine unrelated concerns in one check (e.g., `isAdmin && hasItems && !isExpired`)

## How to detect

### Cognitive Complexity score

Use the SonarQube cognitive complexity algorithm as the quantitative backbone. This gives a single numeric score that correlates with how hard the control flow is to follow.

**Base increment (+1 each):**
- `if`, `else if`, `else`
- `switch` (once per switch, not per case)
- `for`, `for...in`, `for...of`
- `while`, `do...while`
- `catch`
- `break` or `continue` to a label
- Each switch between `&&` and `||` in a boolean expression (e.g., `a && b || c` = +2)
- Ternary `? :`
- Recursive calls (function calling itself)

**Nesting penalty (+1 per enclosing nesting level):**
Applied to: `if`, `else if`, `else`, `switch`, `for`, `for...of`, `for...in`, `while`, `do...while`, `catch`, ternary `? :`

Nesting levels established by: `if`, `else if`, `else`, `switch`, `for`, `while`, `do...while`, `catch`, nested functions/lambdas/arrow functions

**NOT counted:** `case` labels, `finally`, `try`, simple `return`/`throw`, `break` without label

### Classify after scoring

After computing the CC score, classify which classes contribute most:
- **Deep nesting** — max nesting depth ≥ 4
- **Tangled branching** — 4+ branches in a chain, or switch with nested logic in cases
- **Boolean chain** — expressions with mixed `&&`/`||` operators

Report the classification alongside the score — the doer needs to know *which kind* of tangling to address.

## Severity rules

- **warning** — CC score > 2× threshold (e.g., 20+ when threshold is 10)
- **suggestion** — CC score > threshold but ≤ 2× threshold

## Examples

```typescript
// CLASS 1: deep nesting (CC ≈ 14)
// Scanner flags: "deep nesting — max depth 5, CC 14"
function resolveFeatureFlags(user, env, overrides) {
  if (env.featureFlags) {                               // +1, depth 1
    for (const flag of env.featureFlags) {              // +1 +1n, depth 2
      if (flag.enabled) {                               // +1 +2n, depth 3
        if (user.roles.includes(flag.requiredRole)) {   // +1 +3n, depth 4
          if (!overrides?.disabled?.includes(flag.id)) { // +1 +4n +1bool, depth 5
            // reader has lost context of what's true here
          }
        }
      }
    }
  }
}

// CLASS 2: tangled branching (CC ≈ 12)
// Scanner flags: "tangled branching — 5-way if/else chain with nested logic"
function handleEvent(event) {
  if (event.type === 'click') {
    if (event.target.matches('.btn')) { /* ... */ }
    else if (event.target.matches('.link')) { /* ... */ }
  } else if (event.type === 'keydown') {
    if (event.key === 'Enter') { /* ... */ }
    else if (event.key === 'Escape') { /* ... */ }
  } else if (event.type === 'scroll') {
    // ... yet another branch
  }
  // 5 paths, nested 2 deep. Hard to verify all cases.
}

// CLASS 3: boolean chain (CC ≈ 8)
// Scanner flags: "boolean chain — mixed && || with 4 clauses"
function canAccess(user, resource, context) {
  if (user.isAdmin || user.roles.includes('editor')
      && resource.isPublic || context.bypassAuth
      && !resource.isArchived) {
    // What combination of conditions reaches here?
    // Reader must mentally parse operator precedence.
  }
}
```

---
name: complexity-scorer
description: 🌿 Score cognitive complexity of TypeScript/JavaScript functions using the SonarQube algorithm. Use when analyzing function complexity, ranking functions by complexity score, or when eslint-plugin-sonarjs is not available in the project. Triggers when the user asks to score, measure, or analyze function complexity.
user-invokable: true
disable-model-invocation: false
---

# Cognitive Complexity Scorer

When asked to score a function's cognitive complexity, use the SonarQube cognitive complexity algorithm as defined below.

## Increment Rules (+1 each)

Each of the following adds +1 to the complexity score:
- `if`, `else if`, `else`
- `switch` (counted once per switch statement, not per case)
- `for`, `for...in`, `for...of`
- `while`, `do...while`
- `catch`
- `break` or `continue` to a label
- Sequences of logical operators: each SWITCH between `&&` and `||` in a chain (e.g., `a && b && c` = +1, but `a && b || c` = +2)
- Ternary operator `? :`
- Recursive calls (function calling itself)

## Nesting Increment (+1 per nesting level)

The following constructs add +1 for EACH level of enclosing nesting when they appear:
- `if`, `else if`, `else`
- `switch`
- `for`, `for...in`, `for...of`
- `while`, `do...while`
- `catch`
- Ternary `? :`

Nesting levels are established by:
- `if`, `else if`, `else`, `switch`, `for`, `while`, `do...while`, `catch`
- Nested functions, lambdas, arrow functions

## NOT Counted

- `case` labels within a switch (the switch itself is counted once)
- `finally` blocks
- `try` (only `catch` adds complexity)
- Simple `return` or `throw` statements
- `break` without a label (inside switch or loop)

## Scoring Example

```typescript
function processOrder(order) {          // +0 (function declaration, no increment)
  if (!order) {                         // +1 (if, nesting 0)
    return null;
  }

  for (const item of order.items) {     // +1 (for...of, nesting 0)
    if (item.quantity > 0) {            // +2 (if, nesting 1)
      if (item.discount                 // +3 (if, nesting 2)
          && item.discount > 0) {       //    (no extra, same operator &&)
        // apply discount
      } else if (item.coupon            // +1 (else if)
                 || item.promotion) {   // +1 (switch from && to ||... wait, first operator in chain)
        // apply coupon                 // Actually: `item.coupon || item.promotion` = +1 for the ||
      }
    }
  }
}
// Total: 1 + 1 + 2 + 3 + 1 + 1 = 9
```

## Output Format

When scoring a function, output:

```
Function: [name]
File: [path]:[line]
Cognitive Complexity: [score]

Breakdown:
  L[N]: [code snippet] ......... +[increment] (nesting: [level])
  L[N]: [code snippet] ......... +[increment] (nesting: [level])
  ...

Total: [score]
```

When ranking multiple functions, output a sorted table:

```
| Rank | Function | File:Line | Complexity |
|------|----------|-----------|-----------|
| 1    | name     | path:N    | score     |
| 2    | name     | path:N    | score     |
```

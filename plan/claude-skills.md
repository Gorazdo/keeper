Here's the full list based on the official docs and community reference:

---

**`name`** — The slash command identifier. Becomes `/your-name` in the terminal.

Rules: lowercase letters, numbers, hyphens only; max 64 chars. Consider using gerund form (`deploying-app`, `reviewing-code`) since it reads naturally as a capability description. The directory name is the fallback if omitted.

---

**`description`** — The most important field. It's injected into Claude's system prompt and is the primary mechanism for auto-discovery. Write it in third person ("Processes Excel files…" not "Process Excel files…") since it sits inside a system prompt context.

Include both *what* it does and *when* to trigger it. Anthropic notes that Claude tends to "undertrigger" skills, so descriptions should be a bit "pushy" — explicitly listing trigger phrases and edge cases. For example, instead of "Helps with dashboards," write "Builds dashboards to display data. Use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of data, even if they don't explicitly ask for a 'dashboard.'" Max 1024 chars.

---

**`user-invocable`** — Controls whether the skill appears in the `/` autocomplete for the human.

Set to `false` for background knowledge skills that Claude should pick up automatically but that make no sense as a manual command. Example: a `legacy-system-context` skill that explains how an old system works. Claude should know this when relevant, but `/legacy-system-context` isn't a meaningful action for users to take. Defaults to `true`.

---

**`disable-model-invocation`** — Controls whether Claude can auto-trigger the skill.

Set to `true` for anything with side effects or where timing matters. Think `/commit`, `/deploy`, `/send-slack-message` — you don't want Claude deciding to deploy because your code looks ready. This field also removes the skill description from Claude's context entirely, so Claude won't even know the skill exists unless the user explicitly calls it. Defaults to `false`.

---

**`allowed-tools`** — Scopes which tools the skill can use. Both a pre-approval (no permission prompts for these) and a capability restriction (the skill can't use anything else).

Format: comma-separated, with glob patterns for Bash. Example: `Bash(git add:*), Bash(git status:*), Bash(git commit:*), Read, Write`. When omitted, the skill inherits the tool capabilities of the parent agent — which is fine for knowledge-only skills but risky for anything that runs commands.

---

**`argument-hint`** — Placeholder text shown in the `/` autocomplete to hint what arguments the command expects.

Example: `"[environment]"` or `"[issue-number] [priority]"`. Purely cosmetic but helps your team understand usage at a glance.

---

**`model`** — Override the model for this skill's execution.

Example: `claude-3-5-haiku-20241022` for cheap/fast tasks like linting or simple lookups, or a specific Opus version for complex reasoning. Useful for cost control — not every skill needs your most expensive model.

---

**`context: fork`** — Runs the skill in a forked (separate) context window.

Use this when the skill is heavy or when you don't want its intermediate work polluting your main conversation. The skill gets its own context, does its thing, and returns a result. Essential for skills that scan entire repos or generate large amounts of intermediate text.

---

**`agent`** — Specifies which agent type executes the skill.

Values like `general-purpose` or specific subagent names. Use when you want the skill to run as a subagent with its own persona/context rather than inline in the main conversation.

---

**`hooks`** — Lifecycle hooks that fire at specific points during skill execution.

Supports `PreToolUse`, `PostToolUse`, and `Stop` events. Each hook has a `matcher` (which tool to intercept), a `command` to run, and optionally `once: true` to fire only the first time. Example from the docs:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
          once: true
```

Use for validation gates, auto-formatting after writes, or cleanup on completion.

---

**`once`** (inside hooks) — If `true`, the hook fires only on the first matching event, not every time.

---

**`license`** — Part of the Agent Skills Open Standard. Relevant if you're distributing skills publicly or across teams. Example: `Apache-2.0`.

---

**`compatibility`** / **`metadata`** — Also part of the Open Standard. Use `compatibility` to declare required tools or dependencies, and `metadata` for arbitrary key-value pairs (version, author, etc.).

---

**Combining the invocation flags — a quick matrix:**

| `user-invocable` | `disable-model-invocation` | Result |
|---|---|---|
| `true` (default) | `false` (default) | Both human and Claude can trigger |
| `true` | `true` | Human-only command (deploy, commit) |
| `false` | `false` | Claude-only background knowledge |
| `false` | `true` | Nobody can trigger it — don't do this |
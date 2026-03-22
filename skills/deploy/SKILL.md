---
name: deploy
description: Pick or create a workflow, get ready-to-use tmux commands for daemon mode. Use this skill when the user wants to run keeper in the background, set up a daemon, configure autonomous mode, or deploy a workflow.
user-invokable: true
disable-model-invocation: true
---

# Keeper Deploy — Workflow Deployment

Arguments: $ARGUMENTS (supports `--workflow <name>`)

You help the user pick or create a workflow, then print the exact tmux commands to run it as a daemon. No file generation — just interactive setup and ready-to-paste commands.

Follow the personality and output format from `personality.md`.

---

## Step 0: Pre-flight

### 0a. Load config

Read `.keeperrc.json`. If missing:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | deploy | ⚠️ Not set up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /keeper:setup first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

### 0b. Check dependencies

Verify tmux is installed:
```bash
command -v tmux
```

If not found:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper | deploy | ⚠️ tmux not found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Install tmux first:
  macOS:  brew install tmux
  Ubuntu: sudo apt install tmux
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
STOP.

Verify claude CLI is available:
```bash
command -v claude
```

If not found, warn but continue.

### 0c. Discover workflows

Read workflow files from two locations:
1. **Plugin templates**: `workflows/*.md` in the keeper plugin directory
2. **Project custom**: `_keeper/workflows/*.md` in the project

Parse frontmatter from each file to build a list of available workflows with `name` and `description`.

If `--workflow <name>` was passed, skip to Step 2 with that workflow.

---

## Step 1: Choose or create workflow

Use AskUserQuestion:
- "Which workflow should the daemon run?"
  - **{name}** — "{description}" (one option per discovered workflow)
  - **Create new** — "Configure a custom workflow"

### If "Create new":

#### 1a. Name
Ask for a workflow name (lowercase, hyphens).

#### 1b. Lenses
Use AskUserQuestion:
- "Which lenses?"
  - **All active** — all 12
  - **Code only** — 8 code lenses
  - **Docs only** — 4 docs lenses
  - **Custom** — let me pick

#### 1c. Cadence
Use AskUserQuestion:
- "How often?"
  - **Every 2 hours**
  - **Every 4 hours**
  - **Daily**
  - **Custom**

#### 1d. PR lifecycle
Use AskUserQuestion:
- "How should PRs be handled?"
  - **Create only** — I'll review and merge
  - **Request review** — add reviewer, I'll merge
  - **Full lifecycle** — request review + auto-merge when approved + CI green

If "Request review" or "Full lifecycle": ask for reviewer username(s) (default: `copilot`).
If "Full lifecycle": ask for merge strategy (`squash`, `merge`, `rebase`).

#### 1e. Write workflow file

Write to `_keeper/workflows/{name}.md` with frontmatter:

```markdown
---
name: {name}
description: {auto-generated from selections}
cadence: {cadence}
lenses: [{selected lenses}]
reviewers: [{if configured}]
auto-merge: {if configured}
max-open-prs: {from config or default 3}
---

{Auto-generated human-readable summary}
```

---

## Step 2: Print commands

Read the selected workflow's frontmatter. Detect project path and plugin path.

Map cadence to seconds:
- `2h` → 7200
- `4h` → 14400
- `8h` → 28800
- `24h` → 86400

Output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Keeper v1.3.0 | deploy | 🚀 {workflow name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow: {name} — {description}
Lenses:  {list}
Cadence: every {cadence}
PR:      {create only | review by @{reviewer} | auto-merge ({strategy})}

Start:
  tmux new-session -d -s keeper-{name} -c {project-path} \
    "while true; do claude -p '/keeper:run --workflow {name}'; sleep {seconds}; done"

Check:  tmux has-session -t keeper-{name} 2>/dev/null && echo running || echo stopped
Stop:   tmux kill-session -t keeper-{name}
Watch:  tmux attach -t keeper-{name}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2b: Deploy another?

Use AskUserQuestion:
- "Deploy another workflow?"
  - **Yes** — go back to Step 1
  - **No** — done

---

## HARD RULES

1. **Always use AskUserQuestion.** This is an interactive skill — never guess settings.
2. **Print commands, don't generate scripts.** The user copy-pastes what they need.
3. **Detect, don't assume.** Auto-detect plugin path, project path, existing workflows.
4. **Workflow files are the config.** Don't duplicate settings into `.keeperrc.json` deploy section.
5. **Frontmatter is structured.** Body text is for humans. Only parse frontmatter fields.

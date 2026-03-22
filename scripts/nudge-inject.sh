#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Keeper Nudge — Inject
# Runs on UserPromptSubmit. If a nudge queue exists
# and cooldown has elapsed, injects the file list
# as additional context for Claude to run lens analysis.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

QUEUE_FILE="${KEEPER_DIR}/nudge-queue.txt"
STATE_FILE="${KEEPER_DIR}/nudge-last"
CONSUMED="${QUEUE_FILE}.consumed"

guard_keeper_exists
guard_no_lock
guard_nudge_enabled

[ -f "$QUEUE_FILE" ] || exit 0

# Cooldown check
COOLDOWN_MINUTES=$(nudge_conf cooldown_minutes 30)

if [ -f "$STATE_FILE" ]; then
  LAST=$(cat "$STATE_FILE")
  if [ -n "$LAST" ]; then
    # macOS date -j vs GNU date -d
    LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${LAST%%Z*}" "+%s" 2>/dev/null || date -d "$LAST" "+%s" 2>/dev/null || echo 0)
    NOW_EPOCH=$(date "+%s")
    ELAPSED=$(( (NOW_EPOCH - LAST_EPOCH) / 60 ))
    [ "$ELAPSED" -lt "$COOLDOWN_MINUTES" ] && exit 0
  fi
fi

# Atomic consume
mv "$QUEUE_FILE" "$CONSUMED" 2>/dev/null || exit 0

echo "---"
echo "keeper-nudge-queue: Files edited since last nudge check. Run nudge lenses on these files using haiku scanner, then present findings if any."
cat "$CONSUMED"
echo "---"
rm -f "$CONSUMED"

# Update state — plain text timestamp, one line
date -u "+%Y-%m-%dT%H:%M:%SZ" > "$STATE_FILE"

exit 0

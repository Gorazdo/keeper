#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Keeper Nudge — Collect
# Runs on PostToolUse (Write|Edit). Appends the
# edited file path to _keeper/nudge-queue.txt.
# No analysis — just collect for later lens scan.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

QUEUE_FILE="${KEEPER_DIR}/nudge-queue.txt"

guard_keeper_exists
guard_no_lock

FILE_PATH=$(cat | extract_file_path)
[ -z "$FILE_PATH" ] && exit 0

guard_not_keeper_file "$FILE_PATH"
guard_nudge_enabled

# Deduplicate
[ -f "$QUEUE_FILE" ] && grep -qF "$FILE_PATH" "$QUEUE_FILE" 2>/dev/null && exit 0

echo "$FILE_PATH" >> "$QUEUE_FILE"
exit 0

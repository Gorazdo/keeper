#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Keeper Scripts — Shared Library
# Common guards and helpers for nudge hooks.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

KEEPER_DIR="${PWD}/_keeper"

# ── Config ─────────────────────────────────
# _keeper/nudge.conf is key=value, written by setup.
#   enabled=true
#   cooldown_minutes=30

nudge_conf() {
  local key="$1" default="$2"
  local conf="${KEEPER_DIR}/nudge.conf"
  if [ -f "$conf" ]; then
    local val
    val=$(grep "^${key}=" "$conf" 2>/dev/null | head -1 | cut -d= -f2-)
    [ -n "$val" ] && echo "$val" && return
  fi
  echo "$default"
}

# ── Guards ─────────────────────────────────
# Each exits 0 silently if the condition fails.
# Hook scripts must never block the user.

guard_keeper_exists() { [ -d "$KEEPER_DIR" ] || exit 0; }
guard_no_lock() {
  local lockfile="${KEEPER_DIR}/.lock"
  [ -f "$lockfile" ] || return 0
  # Treat locks older than 60 minutes as stale
  local stamp
  stamp=$(cat "$lockfile" 2>/dev/null)
  if [ -n "$stamp" ]; then
    local lock_epoch now_epoch elapsed
    lock_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${stamp%%Z*}" "+%s" 2>/dev/null || date -d "$stamp" "+%s" 2>/dev/null || echo 0)
    now_epoch=$(date "+%s")
    elapsed=$(( (now_epoch - lock_epoch) / 60 ))
    [ "$elapsed" -ge 60 ] && return 0
  fi
  exit 0
}
guard_nudge_enabled() { [ "$(nudge_conf enabled true)" = "false" ] && exit 0; return 0; }

guard_not_keeper_file() {
  case "$1" in
    */_keeper/*|*/.keeperrc.json) exit 0 ;;
  esac
}

# ── Lock ───────────────────────────────────

create_lock() {
  date -u "+%Y-%m-%dT%H:%M:%SZ" > "${KEEPER_DIR}/.lock"
}

# ── Helpers ────────────────────────────────

# Extract file_path from hook stdin JSON.
extract_file_path() {
  grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//'
}

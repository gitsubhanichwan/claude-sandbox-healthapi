#!/usr/bin/env bash
# PreToolUse(Bash): before `git commit`, run scripts/precommit.sh.
# FAIL-OPEN: if the check cannot run, allow. Exit 2 (block) only when checks fail.
set -uo pipefail
input=$(cat 2>/dev/null || true)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
fi
[ -z "${cmd:-}" ] && cmd="$input"
case "$cmd" in *"git commit"*) : ;; *) exit 0 ;; esac
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
script="$root/scripts/precommit.sh"
[ -f "$script" ] || exit 0
if ! out=$(cd "$root" && bash "$script" 2>&1); then
  echo "BLOCKED: scripts/precommit.sh failed. Fix before committing." >&2
  printf '%s\n' "$out" | tail -40 >&2
  exit 2
fi
exit 0

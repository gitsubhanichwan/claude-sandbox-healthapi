#!/usr/bin/env bash
# SessionStart: make drift behind origin/main VISIBLE before editing begins.
# Fast-forwards ONLY when: clean tree, on main, no local commits, behind.
# Otherwise only reports. Never rebases, stashes or discards. Silent when current.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git fetch origin --quiet 2>/dev/null || true
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')
DIRTY=$(git status --porcelain --untracked-files=no 2>/dev/null | grep -c . || true)
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
[ "$BEHIND" -eq 0 ] && [ "$DIRTY" -eq 0 ] && exit 0
if [ "$BEHIND" -gt 0 ] && [ "$DIRTY" -eq 0 ] && [ "$BRANCH" = "main" ] && [ "$AHEAD" -eq 0 ]; then
  git merge --ff-only origin/main --quiet 2>/dev/null && {
    echo "Fast-forwarded main +${BEHIND} commit(s) from origin. You are on current code."; exit 0; }
fi
NOTE=""
[ "$BEHIND" -gt 0 ] && NOTE="${BEHIND} commit(s) behind origin/main"
[ "$DIRTY" -gt 0 ]  && NOTE="${NOTE:+$NOTE, }${DIRTY} uncommitted file(s)"
[ "$AHEAD" -gt 0 ]  && NOTE="${NOTE:+$NOTE, }${AHEAD} unpushed commit(s)"
echo "Git state on '${BRANCH}': ${NOTE}. Working tree NOT modified. If the task depends on current code, say so before editing."
exit 0

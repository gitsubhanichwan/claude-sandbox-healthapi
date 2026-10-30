#!/usr/bin/env bash
# Fast local checks, run automatically before every Claude Code commit.
set -euo pipefail
echo "== gofmt"
unformatted=$(gofmt -l . | grep -v '^vendor/' || true)
[ -z "$unformatted" ] || { echo "gofmt needed on:"; echo "$unformatted"; exit 1; }
echo "== go vet"; go vet ./...
echo "== go test"; go test ./...
if command -v terraform >/dev/null 2>&1; then
  echo "== terraform fmt"; terraform fmt -check -recursive infra
fi
echo "precommit OK"

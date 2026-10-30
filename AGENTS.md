# AGENTS.md: House Rules (short form for any AI coding agent)

Canonical source: `CLAUDE.md`. It wins on any conflict.

- Never push to `main`; feature branch + PR only. Branch off freshly fetched `origin/main`.
- Never create, change or delete AWS resources without explicit human approval.
- Never put credentials, account IDs or internal info in the repo (it is public).
- Production deploys the exact image digest tested in staging. Never rebuild for production.
- Stay in scope; no drive-by refactors; no new dependencies without asking.

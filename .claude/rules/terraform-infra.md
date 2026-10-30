---
paths:
  - "infra/**"
---
# Terraform infrastructure

**Covers:** AWS resources for both environments, IAM roles, OIDC trust, tagging.

**Run:** `terraform -chdir=infra fmt -check -recursive && terraform -chdir=infra validate && terraform -chdir=infra plan`

## Why it exists
A plan that looks small can replace a service or widen an IAM policy. Replacing the
Express service changes its endpoint; widening a deploy role lets staging deploy to production.

## What not to do
- Do not apply from a feature branch. Apply only from `main` so state matches the code on `main`.
- Do not loosen the OIDC trust `sub` condition (`repo:<owner>/<repo>:environment:<env>`).
- Do not grant `*` resources for write actions in deploy roles.
- Show the plan summary (create / change / destroy) and wait for approval before any apply.

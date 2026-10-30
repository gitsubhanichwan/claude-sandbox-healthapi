---
paths:
  - ".github/workflows/**"
  - ".github/scripts/**"
---
# Deploy pipeline

**Covers:** test -> build -> staging -> approval -> production, with the same image digest.

**Run:** push a feature branch and check the PR run: `gh run list --limit 3`

## Why it exists
The pipeline is the only route to production. Breaking its gates fails silently:
a deploy that skips approval or rebuilds the image still looks green.

## What not to do
- Do not remove `environment: production` from the production job (it is the approval gate).
- Do not rebuild in the production job; deploy `needs.deploy-staging.outputs.digest`.
- Do not print the role ARN or account ID; keep `mask-aws-account-id: true`.
- Pin third-party actions to a commit SHA.

# CLAUDE.md: Project Instructions for Claude Code

## Project Overview

healthapi: a minimal Go REST API used as an end-to-end trial of Claude Code,
from coding to deployment on AWS. The app is deliberately trivial; the value
is the delivery pipeline and guardrails around it.

- App: Go (stdlib `net/http` only), `GET /health`, `GET /version` (reads `APP_VERSION`).
- Container: multi-stage Dockerfile, distroless nonroot runtime, port 8080.
- Infra: Terraform in `infra/`, AWS `ap-southeast-3` (Jakarta), ECS Express Mode (Fargate),
  two environments (`staging`, `production`) sharing one ALB.
- Deploy: merge to `main` -> CI (`test`, `docker`) -> deploy staging + smoke test ->
  **manual approval** (GitHub Environment `production`) -> deploy the SAME image digest
  to production + smoke test.

## Vocabulary

| Say this | Means | In code / config |
|---|---|---|
| **staging** / **production** | The two environments | Terraform module `infra/modules/environment`, GitHub Environments of the same name |
| **deploy role** | IAM role GitHub Actions assumes via OIDC, one per environment | `aws_iam_role.deploy` in the environment module; secret `AWS_DEPLOY_ROLE_ARN` per GitHub Environment |
| **bootstrap** | Terraform that creates the S3 state bucket | `infra/bootstrap/` (local state, applied once) |
| **sandbox profile** | The human's local AWS CLI profile for the dev account | `--profile sandbox` |

## Map

- `main.go`, `handler.go`, `handler_test.go`: the app.
- `Dockerfile`, `.dockerignore`: image build.
- `infra/main.tf`: shared resources (ECR, GitHub OIDC provider, infrastructure role).
- `infra/modules/environment/`: per-environment cluster, Express service, log group, execution + deploy roles.
- `.github/workflows/ci.yml`: CI + CD. `.github/scripts/deploy.sh`, `smoke-test.sh`: deploy and verify.

## Conventions

- Go: stdlib first, no new dependencies without asking. Run `gofmt`.
- Terraform: `default_tags` (Project, Owner, ManagedBy, Environment) on every resource.
  Never hardcode the AWS account ID (use `aws_caller_identity`). The repo is PUBLIC.
- No credentials, account IDs or internal info in code, commits, PR text or logs.
- Commit messages: `[area] Short description` where area is `app`, `infra`, `ci` or `docs`.

## Do NOT

- Push to `main`. Always a feature branch + PR (`main` is protected; a hook also blocks it).
- Run `terraform apply` / `destroy` or any `aws ... create|put|update|delete` without explicit approval per command.
- Read `~/.aws`, `.env`, `*.tfstate` (denied in settings).
- Build a new image for production. Production always deploys the digest tested in staging.
- Refactor working code unless asked.

## Pre-Commit Checklist (MANDATORY)

`scripts/precommit.sh` runs automatically before every commit (gofmt, go vet, go test,
terraform fmt). Also, when relevant:
1. Infra change: `terraform -chdir=infra validate` and `terraform -chdir=infra plan`, and show
   the create / change / destroy counts. Any unexpected destroy or replace: STOP and report.
2. CI change: explain how the change will be verified on the next run.

## Autonomy Rules

You may, without asking: read files, edit code, run tests/lint/plan, create branches,
commit, push feature branches, open PRs, read AWS state with read-only commands
(`describe`, `list`, `get`).

STOP and ask before: anything that creates, changes or deletes AWS resources;
changing IAM policies or trust relationships; changing branch protection or GitHub
Environments; deleting files; adding dependencies.

Before any AWS command, run `aws sts get-caller-identity --profile sandbox` and confirm the
account is the DEVELOPMENT account.

## Debugging Discipline

1. Collect symptoms (CI logs, ECS deployment status, CloudWatch logs).
2. Read the code path. 3. `git log --oneline -20 -- <files>`.
4. Reproduce deterministically. 5. Regression test for logic or contract bugs.
3-strike rule: same fix fails 3 times, stop and ask.

# Infrastructure

Terraform for the healthapi trial on AWS (`ap-southeast-3`). Run with `AWS_PROFILE` set; no credentials or account IDs live in this repo.

1. `bootstrap/` creates the S3 bucket for remote state (versioning, SSE, public access blocked, TLS-only). It uses local state. Apply once, then read the `state_bucket` output.
2. The root module (this folder) holds the shared ECR repository and GitHub OIDC provider, plus a `staging` and a `production` instance of `modules/environment` (cluster, ECS Express Mode service, log group, ECS roles, and a GitHub deploy role bound to the matching GitHub Environment).

```sh
terraform init -backend-config="bucket=<state_bucket>"
terraform plan
```

Notes:
- The Express service needs an image to exist at creation. Push an image tagged `bootstrap` to ECR first (or apply with `-target=aws_ecr_repository.app` and push before applying the rest). Terraform ignores later image/env changes; CI owns deploys.
- `aws_ecs_express_gateway_service` has no `propagate_tags` argument, so tags set via provider `default_tags` apply to the service, not necessarily to its tasks.
- ECS Express Mode places services that share a VPC and subnet type behind one ALB (up to 25, host-header routing). Both environments use the default VPC and subnets and one shared infrastructure role, so they should share an ALB; this is decided by ECS, not by Terraform, and can only be confirmed after the first apply.
- Autoscaling is capped at 1 task per environment for the trial.
- GitHub Environments `staging` and `production` must exist (production requires a reviewer) and deploy only from `main`; the OIDC `sub` claim in the deploy roles matches them.

## Apply order (from `main`, each step approved separately)
1. `bootstrap/`: apply, read `state_bucket`.
2. Root: `terraform init -backend-config="bucket=<state_bucket>"`, then `apply -target=aws_ecr_repository.app`.
3. Build and push the app image tagged `bootstrap` to ECR.
4. Root: full `apply`.

#!/usr/bin/env bash
# Deploy an image to an Express Mode service and wait for the deployment result.
# Usage: deploy.sh <environment> <image> <app-version>
# Expects AWS credentials and AWS_REGION in the environment.
#
# Express Mode rolls out a canary and has the deployment circuit breaker with
# automatic rollback enabled, so a revision that fails its health checks is
# rolled back by ECS. This script only has to report the outcome.
set -euo pipefail

env_name=$1
image=$2
version=$3

cluster="healthapi-${env_name}"
service="healthapi-${env_name}"
timeout_seconds=${DEPLOY_TIMEOUT_SECONDS:-1500}

latest_deployment() {
  aws ecs list-service-deployments \
    --cluster "$cluster" --service "$service" \
    --query 'sort_by(serviceDeployments, &createdAt)[-1].serviceDeploymentArn' \
    --output text
}

service_arn=$(aws ecs describe-services \
  --cluster "$cluster" --services "$service" \
  --query 'services[0].serviceArn' --output text)

before=$(latest_deployment)

input=$(mktemp)
cat >"$input" <<EOF
{
  "serviceArn": "${service_arn}",
  "primaryContainer": {
    "image": "${image}",
    "containerPort": 8080,
    "awsLogsConfiguration": {
      "logGroup": "/ecs/${service}",
      "logStreamPrefix": "app"
    },
    "environment": [
      { "name": "APP_VERSION", "value": "${version}" }
    ]
  }
}
EOF

echo "Updating ${service} to ${version}"
aws ecs update-express-gateway-service --cli-input-json "file://${input}" >/dev/null
rm -f "$input"

# Wait for ECS to start a deployment for the new revision.
deployment=$before
for _ in $(seq 1 12); do
  deployment=$(latest_deployment)
  [ "$deployment" != "$before" ] && break
  sleep 10
done

if [ "$deployment" = "$before" ]; then
  echo "::warning::No new deployment was created (the service may already run this revision); relying on the smoke test."
  exit 0
fi

echo "Deployment started: ${deployment##*/}"
deadline=$((SECONDS + timeout_seconds))
last=""
while [ "$SECONDS" -lt "$deadline" ]; do
  status=$(aws ecs describe-service-deployments \
    --service-deployment-arns "$deployment" \
    --query 'serviceDeployments[0].status' --output text)
  if [ "$status" != "$last" ]; then
    echo "Deployment status: ${status}"
    last=$status
  fi
  case "$status" in
    SUCCESSFUL)
      exit 0
      ;;
    STOPPED | ROLLBACK_*)
      reason=$(aws ecs describe-service-deployments \
        --service-deployment-arns "$deployment" \
        --query 'serviceDeployments[0].statusReason' --output text || true)
      echo "::error::Deployment ended as ${status}: ${reason}. ECS rolls back failed deployments automatically; the previous revision keeps serving."
      exit 1
      ;;
  esac
  sleep 15
done

echo "::error::Timed out after ${timeout_seconds}s waiting for the deployment (last status: ${last})."
exit 1

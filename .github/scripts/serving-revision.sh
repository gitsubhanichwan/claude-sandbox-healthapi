#!/usr/bin/env bash
# Print the image and APP_VERSION an Express Mode service is serving now, as
# GITHUB_OUTPUT lines (image=..., version=...). Run before a deploy to record the
# rollback target.
# Usage: serving-revision.sh <environment>
# Expects AWS credentials and AWS_REGION in the environment.
set -euo pipefail

env_name=$1

service_arn=$(aws ecs describe-services \
  --cluster "healthapi-${env_name}" --services "healthapi-${env_name}" \
  --query 'services[0].serviceArn' --output text)

# CI deploys one at a time, so there is normally a single active configuration.
# If there are more, the newest is the one ECS is moving traffic to.
container=$(aws ecs describe-express-gateway-service \
  --service-arn "$service_arn" \
  --query 'sort_by(service.activeConfigurations, &createdAt)[-1].primaryContainer' \
  --output json)

image=$(jq -r '.image // empty' <<<"$container")
version=$(jq -r '[.environment[]? | select(.name == "APP_VERSION") | .value][0] // empty' <<<"$container")

if [ -z "$image" ] || [ -z "$version" ]; then
  echo "::error::Could not read the image and APP_VERSION serving ${env_name}; not deploying without a rollback target." >&2
  exit 1
fi

# Log only the version: the image URI contains the registry host.
echo "Serving ${env_name} before deploy: ${version}" >&2
echo "image=${image}"
echo "version=${version}"

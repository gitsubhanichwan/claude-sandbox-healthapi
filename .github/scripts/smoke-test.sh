#!/usr/bin/env bash
# Smoke test a deployed environment.
# Usage: smoke-test.sh <environment> <expected-version>
# Expects AWS credentials and AWS_REGION in the environment.
set -euo pipefail

env_name=$1
expected=$2

service_arn=$(aws ecs describe-services \
  --cluster "healthapi-${env_name}" --services "healthapi-${env_name}" \
  --query 'services[0].serviceArn' --output text)
endpoint=$(aws ecs describe-express-gateway-service \
  --service-arn "$service_arn" \
  --query 'service.activeConfigurations[0].ingressPaths[0].endpoint' --output text)

echo "Smoke testing ${endpoint}"

# The new revision just took all traffic; allow a short window for stragglers.
for attempt in $(seq 1 12); do
  health=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "${endpoint}/health" || true)
  actual=$(curl -s --max-time 10 "${endpoint}/version" | jq -r '.version // empty' 2>/dev/null || true)
  echo "attempt ${attempt}: /health=${health} /version=${actual:-<none>}"
  if [ "$health" = "200" ] && [ "$actual" = "$expected" ]; then
    echo "Smoke test passed"
    exit 0
  fi
  sleep 10
done

echo "::error::Smoke test failed (expected /health 200 and /version ${expected})."
exit 1

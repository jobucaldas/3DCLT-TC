#!/usr/bin/env bash
#### Script para criar configuracão demo dos pods no cluster kubernetes
set -euo pipefail

cd "$(dirname "$0")"

REGION="${REGION:-us-east-1}"
PROJECT="${PROJECT:-togglemaster}"

AUTH_PATH="/auth"
FLAG_PATH="/flags"
TARGETING_PATH="/targeting"
EVAL_PATH="/evaluation"

# Pass API_KEY=tm_key_... when running.
# If omitted, script tries to read it from AWS Secrets Manager (ESO source), not from the ESO-created k8s Secret.
API_KEY="${API_KEY:-}"
if [ -z "$API_KEY" ] && command -v aws >/dev/null 2>&1; then
  API_KEY="$(aws secretsmanager get-secret-value \
    --region "$REGION" \
    --secret-id "$PROJECT/evaluation-service" \
    --query SecretString \
    --output text 2>/dev/null | sed -n 's/.*"SERVICE_API_KEY"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi

if [ -z "$API_KEY" ] || [ "$API_KEY" = "placeholder" ]; then
  echo "Missing real API key. Run like:"
  echo "API_KEY='tm_key_...' ./k8sBootstrap.sh"
  exit 1
fi

APP_ROLE_ARN="${APP_ROLE_ARN:-$(tofu -chdir=terraform output -raw app_pods_role_arn 2>/dev/null || true)}"
if [ -z "$APP_ROLE_ARN" ]; then
  echo "app_pods_role_arn not found. Run Terraform/OpenTofu after IRSA changes first:"
  echo "  tofu -chdir=terraform apply"
  echo "Then rerun:"
  echo "  API_KEY=tm_key_... ./k8sBootstrap.sh"
  exit 1
fi

echo "Applying app IRSA service accounts..."
kubectl apply -k k8s/evaluation-service >/dev/null
kubectl apply -k k8s/analytics-service >/dev/null
kubectl annotate serviceaccount -n togglemaster-evaluation evaluation-service eks.amazonaws.com/role-arn="$APP_ROLE_ARN" --overwrite >/dev/null
kubectl annotate serviceaccount -n togglemaster-analytics analytics-service eks.amazonaws.com/role-arn="$APP_ROLE_ARN" --overwrite >/dev/null

echo "Forcing ExternalSecrets sync..."
SYNC_TS="$(date +%s)"
kubectl annotate externalsecret -n togglemaster-auth auth-secret force-sync="$SYNC_TS" --overwrite >/dev/null
kubectl annotate externalsecret -n togglemaster-flag flag-secret force-sync="$SYNC_TS" --overwrite >/dev/null
kubectl annotate externalsecret -n togglemaster-targeting targeting-secret force-sync="$SYNC_TS" --overwrite >/dev/null
kubectl annotate externalsecret -n togglemaster-evaluation evaluation-secret force-sync="$SYNC_TS" --overwrite >/dev/null
kubectl annotate externalsecret -n togglemaster-analytics analytics-secret force-sync="$SYNC_TS" --overwrite >/dev/null

kubectl wait externalsecret -n togglemaster-auth auth-secret --for=condition=Ready --timeout=90s
kubectl wait externalsecret -n togglemaster-flag flag-secret --for=condition=Ready --timeout=90s
kubectl wait externalsecret -n togglemaster-targeting targeting-secret --for=condition=Ready --timeout=90s
kubectl wait externalsecret -n togglemaster-evaluation evaluation-secret --for=condition=Ready --timeout=90s
kubectl wait externalsecret -n togglemaster-analytics analytics-secret --for=condition=Ready --timeout=90s

echo "Restarting pods that read secrets as env vars..."
kubectl rollout restart deployment -n togglemaster-auth auth-service
kubectl rollout restart deployment -n togglemaster-flag flag-service
kubectl rollout restart deployment -n togglemaster-targeting targeting-service
kubectl rollout restart deployment -n togglemaster-evaluation evaluation-service
kubectl rollout restart deployment -n togglemaster-analytics analytics-service

kubectl rollout status deployment -n togglemaster-auth auth-service --timeout=120s
kubectl rollout status deployment -n togglemaster-flag flag-service --timeout=120s
kubectl rollout status deployment -n togglemaster-targeting targeting-service --timeout=120s
kubectl rollout status deployment -n togglemaster-evaluation evaluation-service --timeout=120s
kubectl rollout status deployment -n togglemaster-analytics analytics-service --timeout=120s || true

INGRESS_HOST="${INGRESS_HOST:-$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)}"
if [ -z "$INGRESS_HOST" ]; then
  INGRESS_HOST="$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
fi

BASE_URL="${BASE_URL:-http://$INGRESS_HOST}"
if [ "$BASE_URL" = "http://" ]; then
  echo "Ingress host not found. Set BASE_URL manually:"
  echo "BASE_URL=http://<ingress-host> API_KEY='tm_key_...' ./k8sBootstrap.sh"
  exit 1
fi

SQS_URL="${SQS_URL:-$(tofu -chdir=terraform output -raw sqs_queue_url 2>/dev/null || true)}"
DYNAMO_TABLE="${DYNAMO_TABLE:-$(tofu -chdir=terraform output -raw dynamodb_table_name 2>/dev/null || true)}"

echo
echo "Base URL: $BASE_URL"
echo "API key: ${API_KEY:0:12}..."
echo
echo "Cluster state:"
kubectl get externalsecrets -A
kubectl get pods -n togglemaster-auth
kubectl get pods -n togglemaster-flag
kubectl get pods -n togglemaster-targeting
kubectl get pods -n togglemaster-evaluation
kubectl get hpa -n togglemaster-evaluation
kubectl get scaledobject -n togglemaster-analytics
kubectl get ingress -A

echo
echo "Creating/updating demo flags and rules through ingress..."

curl -sS -X POST "$BASE_URL$FLAG_PATH/flags" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"name":"enable-new-dashboard","description":"K8s demo flag always on","is_enabled":true}' || true
echo

curl -sS -X PUT "$BASE_URL$FLAG_PATH/flags/enable-new-dashboard" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"description":"K8s demo flag always on","is_enabled":true}'
echo

curl -sS -X POST "$BASE_URL$TARGETING_PATH/rules" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"flag_name":"enable-new-dashboard","is_enabled":true,"rules":{"type":"PERCENTAGE","value":100}}' || true
echo

curl -sS -X PUT "$BASE_URL$TARGETING_PATH/rules/enable-new-dashboard" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"is_enabled":true,"rules":{"type":"PERCENTAGE","value":100}}'
echo

curl -sS -X POST "$BASE_URL$FLAG_PATH/flags" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"name":"gradual-checkout","description":"K8s demo flag fifty percent","is_enabled":true}' || true
echo

curl -sS -X PUT "$BASE_URL$FLAG_PATH/flags/gradual-checkout" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"description":"K8s demo flag fifty percent","is_enabled":true}'
echo

curl -sS -X POST "$BASE_URL$TARGETING_PATH/rules" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"flag_name":"gradual-checkout","is_enabled":true,"rules":{"type":"PERCENTAGE","value":50}}' || true
echo

curl -sS -X PUT "$BASE_URL$TARGETING_PATH/rules/gradual-checkout" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"is_enabled":true,"rules":{"type":"PERCENTAGE","value":50}}'
echo

cat <<EOF

Done. ESO synced, pods restarted, demo data ready.

Smoke tests:

API_KEY="$API_KEY"
BASE_URL="$BASE_URL"

curl "\$BASE_URL/auth/health"
curl "\$BASE_URL/flags/health"
curl "\$BASE_URL/targeting/health"
curl "\$BASE_URL/evaluation/health"

curl "\$BASE_URL/auth/validate" -H "Authorization: Bearer \$API_KEY"
curl "\$BASE_URL/flags/flags/enable-new-dashboard" -H "Authorization: Bearer \$API_KEY"
curl "\$BASE_URL/targeting/rules/enable-new-dashboard" -H "Authorization: Bearer \$API_KEY"
curl "\$BASE_URL/evaluation/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
curl "\$BASE_URL/evaluation/evaluate?user_id=user-123&flag_name=gradual-checkout"

Apache Bench tests:

# Install if needed: sudo apt install apache2-utils
ab -k -n 2000 -c 50 "\$BASE_URL/evaluation/evaluate?user_id=ab-user&flag_name=enable-new-dashboard"
ab -k -n 20000 -c 200 "\$BASE_URL/evaluation/evaluate?user_id=ab-user&flag_name=enable-new-dashboard"
ab -k -n 10000 -c 100 "\$BASE_URL/evaluation/evaluate?user_id=ab-user&flag_name=missing-flag"

Watch scaling while ab runs:
watch -n 2 'kubectl get hpa -n togglemaster-evaluation; echo; kubectl get pods -n togglemaster-evaluation'
watch -n 2 'kubectl get scaledobject -n togglemaster-analytics; echo; kubectl get pods -n togglemaster-analytics'

SQS / KEDA / DynamoDB checks:
SQS_URL="$SQS_URL"
DYNAMO_TABLE="$DYNAMO_TABLE"

aws sqs get-queue-attributes \
  --queue-url "\$SQS_URL" \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible ApproximateNumberOfMessagesDelayed

for i in \$(seq 1 50); do
  aws sqs send-message \
    --queue-url "\$SQS_URL" \
    --message-body "{\"user_id\":\"manual-\$i\",\"flag_name\":\"enable-new-dashboard\",\"result\":true,\"timestamp\":\"\$(date -u +%FT%TZ)\"}" >/dev/null
done

kubectl get pods -n togglemaster-analytics -w
kubectl logs -n togglemaster-analytics deploy/analytics-service --tail=80
aws dynamodb scan --table-name "\$DYNAMO_TABLE" --limit 5
EOF

#!/usr/bin/env bash
#### Script para configurar servicos localmente
set -euo pipefail

cd "$(dirname "$0")"

AUTH_ENV="../auth-service/.env"
EVAL_ENV="../evaluation-service/.env"
COMPOSE="docker compose -f docker-compose.yml"

AUTH_URL="http://localhost:8001"
FLAG_URL="http://localhost:8002"
TARGETING_URL="http://localhost:8003"
EVAL_URL="http://localhost:8004"

MASTER_KEY="$(grep '^MASTER_KEY=' "$AUTH_ENV" | cut -d= -f2- | tr -d '"')"

if [ -z "$MASTER_KEY" ]; then
  echo "MASTER_KEY not found in $AUTH_ENV"
  exit 1
fi

echo "Creating API key for evaluation-service..."
KEY_RESPONSE="$(curl -s -X POST "$AUTH_URL/admin/keys" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $MASTER_KEY" \
  -d '{"name":"evaluation-service"}')"

SERVICE_API_KEY="$(echo "$KEY_RESPONSE" | sed -n 's/.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

if [ -z "$SERVICE_API_KEY" ]; then
  echo "Could not create key. Response:"
  echo "$KEY_RESPONSE"
  exit 1
fi

echo "Saving key into $EVAL_ENV..."
if grep -q '^SERVICE_API_KEY=' "$EVAL_ENV"; then
  sed -i "s|^SERVICE_API_KEY=.*|SERVICE_API_KEY=\"$SERVICE_API_KEY\"|" "$EVAL_ENV"
else
  printf '\nSERVICE_API_KEY="%s"\n' "$SERVICE_API_KEY" >> "$EVAL_ENV"
fi

echo "Recreating evaluation-service so env reloads..."
$COMPOSE up -d --force-recreate evaluation-service

echo "Creating demo flags and rules..."

curl -s -X POST "$FLAG_URL/flags" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $SERVICE_API_KEY" \
  -d '{"name":"enable-new-dashboard","description":"Demo flag always on","is_enabled":true}' || true
echo

curl -s -X POST "$TARGETING_URL/rules" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $SERVICE_API_KEY" \
  -d '{"flag_name":"enable-new-dashboard","is_enabled":true,"rules":{"type":"PERCENTAGE","value":100}}' || true
echo

curl -s -X POST "$FLAG_URL/flags" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $SERVICE_API_KEY" \
  -d '{"name":"gradual-checkout","description":"Demo flag fifty percent","is_enabled":true}' || true
echo

curl -s -X POST "$TARGETING_URL/rules" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $SERVICE_API_KEY" \
  -d '{"flag_name":"gradual-checkout","is_enabled":true,"rules":{"type":"PERCENTAGE","value":50}}' || true
echo

cat <<EOF

Done. API key saved in $EVAL_ENV

Run these tests:

# Health
curl $AUTH_URL/health
curl $FLAG_URL/health
curl $TARGETING_URL/health
curl $EVAL_URL/health

# Validate generated key
API_KEY="$SERVICE_API_KEY"
curl -i $AUTH_URL/validate -H "Authorization: Bearer \$API_KEY"

# Check flag-service and targeting-service auth works
curl $FLAG_URL/flags/enable-new-dashboard -H "Authorization: Bearer \$API_KEY"
curl $TARGETING_URL/rules/enable-new-dashboard -H "Authorization: Bearer \$API_KEY"

# Test evaluation-service communicating with flag-service + targeting-service
curl "$EVAL_URL/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
curl "$EVAL_URL/evaluate?user_id=user-123&flag_name=gradual-checkout"
curl "$EVAL_URL/evaluate?user_id=user-123&flag_name=missing-flag"

# Negative auth test
curl -i $FLAG_URL/flags/enable-new-dashboard -H "Authorization: Bearer wrong-key"
EOF

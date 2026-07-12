#!/usr/bin/env bash
set -euo pipefail

# Runs PostgreSQL init.sql files from service repos against private RDS databases.
# DB credentials come from AWS Secrets Manager, not Terraform vars or files.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(dirname -- "$SCRIPT_DIR")"

AWS_REGION="${AWS_REGION:-us-east-1}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
SECRET_PREFIX="${SECRET_PREFIX:-togglemaster}"
MIGRATION_POD="${MIGRATION_POD:-postgres-migration}"
POSTGRES_IMAGE="${POSTGRES_IMAGE:-postgres:16-alpine}"
KEEP_POD="${KEEP_POD:-false}"

SERVICES=(
  "auth-service"
  "flag-service"
  "targeting-service"
)

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

get_database_url() {
  local service="$1"
  local secret_id="${SECRET_PREFIX}/${service}"

  aws secretsmanager get-secret-value \
    --region "$AWS_REGION" \
    --secret-id "$secret_id" \
    --query 'SecretString' \
    --output text \
    | jq -r '.DATABASE_URL'
}

create_migration_pod() {
  if kubectl -n "$KUBE_NAMESPACE" get pod "$MIGRATION_POD" >/dev/null 2>&1; then
    echo "Using existing pod: $MIGRATION_POD"
    return
  fi

  echo "Creating migration pod: $MIGRATION_POD"
  kubectl -n "$KUBE_NAMESPACE" run "$MIGRATION_POD" \
    --image="$POSTGRES_IMAGE" \
    --restart=Never \
    --command -- sleep infinity

  kubectl -n "$KUBE_NAMESPACE" wait \
    --for=condition=Ready \
    "pod/$MIGRATION_POD" \
    --timeout=180s
}

cleanup() {
  if [[ "$KEEP_POD" == "true" ]]; then
    echo "Keeping migration pod: $MIGRATION_POD"
    return
  fi

  echo "Deleting migration pod: $MIGRATION_POD"
  kubectl -n "$KUBE_NAMESPACE" delete pod "$MIGRATION_POD" --ignore-not-found >/dev/null
}

migrate_service() {
  local service="$1"
  local sql_file="${REPO_ROOT}/${service}/db/init.sql"
  local remote_sql="/tmp/${service}.sql"
  local database_url

  if [[ ! -f "$sql_file" ]]; then
    echo "Skipping $service: $sql_file not found"
    return
  fi

  echo "Migrating $service"
  database_url="$(get_database_url "$service")"

  if [[ -z "$database_url" || "$database_url" == "null" ]]; then
    echo "Secret ${SECRET_PREFIX}/${service} must contain DATABASE_URL" >&2
    exit 1
  fi

  kubectl -n "$KUBE_NAMESPACE" cp "$sql_file" "${MIGRATION_POD}:${remote_sql}"
  kubectl -n "$KUBE_NAMESPACE" exec "$MIGRATION_POD" -- \
    psql "$database_url" -v ON_ERROR_STOP=1 -f "$remote_sql"
}

main() {
  require_cmd aws
  require_cmd jq
  require_cmd kubectl

  aws sts get-caller-identity >/dev/null
  kubectl get nodes >/dev/null

  create_migration_pod
  trap cleanup EXIT

  for service in "${SERVICES[@]}"; do
    migrate_service "$service"
  done

  echo "All database migrations finished."
}

main "$@"

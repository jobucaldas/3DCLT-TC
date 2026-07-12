#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BASEDIR="$(dirname -- "$SCRIPT_DIR")"

VERSION="${1:-latest}"

find "$BASEDIR" -mindepth 1 -maxdepth 1 -type d -print0 |
  while IFS= read -r -d '' dir; do
    repo_name="$(basename -- "$dir")"

    if [[ "$repo_name" != *-service ]]; then
      echo "Directory $dir does not match *-service pattern, skipping."
      continue
    fi

    if [[ ! -f "$dir/Dockerfile" ]]; then
      echo "No Dockerfile found in $dir, skipping build."
      continue
    fi

    echo "Building Docker image for $repo_name"

    ECR_REPO_URI="$(
      aws ecr describe-repositories \
        --repository-names "$repo_name" \
        --query 'repositories[0].repositoryUri' \
        --output text
    )"

    docker build -t "$ECR_REPO_URI:$VERSION" "$dir"
    docker push "$ECR_REPO_URI:$VERSION"
  done

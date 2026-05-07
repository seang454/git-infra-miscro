#!/bin/bash
# publish-charts.sh
# Packages and publishes all charts to an OCI registry.
# Run this in CI when git-infra-miscro changes.

set -euo pipefail

REGISTRY=${CHART_REGISTRY:-"oci://ghcr.io/seang454/git-infra-miscro/charts"}
VERSION=${CHART_VERSION:-"1.0.0"}
PACKAGE_DIR=${CHART_PACKAGE_DIR:-"/tmp/charts"}

mkdir -p "$PACKAGE_DIR"

CHARTS=(
  "_base:base"
  "_base-identity:base-identity"
  "_base-frontend:base-frontend"
  "_infra-gateway:infra-gateway"
  "_infra-eureka:infra-eureka"
  "_infra-configserver:infra-configserver"
  "_worker:worker"
  "_scheduler:scheduler"
  "_bff:bff"
  "_websocket:websocket"
  "_batch-job:batch-job"
  "_database-migration:database-migration"
)

echo "Packaging and publishing charts to $REGISTRY"

for chart in "${CHARTS[@]}"; do
  folder="${chart%%:*}"
  package="${chart##*:}"
  package_path="$PACKAGE_DIR/$package-$VERSION.tgz"

  echo "Packaging charts/$folder as $package ..."
  helm package "charts/$folder" --version "$VERSION" --destination "$PACKAGE_DIR"

  echo "Pushing $package:$VERSION ..."
  helm push "$package_path" "$REGISTRY"
done

echo "All charts published successfully!"

#!/bin/bash
# publish-charts.sh
# Packages and publishes all charts to an OCI registry.
# Run this in CI when git-infra-miscro changes.

set -e

REGISTRY=${CHART_REGISTRY:-"oci://ghcr.io/YOUR_ORG_OR_USERNAME/charts"}
VERSION=${CHART_VERSION:-"1.0.0"}

CHARTS=(
  "_base"
  "_base-identity"
  "_base-frontend"
  "_infra-gateway"
  "_infra-eureka"
  "_infra-configserver"
  "_worker"
  "_scheduler"
  "_bff"
  "_websocket"
  "_batch-job"
  "_database-migration"
)

echo "Packaging and publishing charts to $REGISTRY"

for chart in "${CHARTS[@]}"; do
  echo "Packaging charts/$chart ..."
  helm package charts/$chart --version $VERSION --destination /tmp/charts/

  echo "Pushing $chart:$VERSION ..."
  helm push /tmp/charts/${chart}-${VERSION}.tgz $REGISTRY
done

echo "All charts published successfully!"

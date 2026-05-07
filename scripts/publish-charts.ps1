# publish-charts.ps1
# Packages and publishes all charts to an OCI registry.
# Run this in CI or from Windows PowerShell when git-infra-miscro changes.

$ErrorActionPreference = "Stop"

$Registry = if ($env:CHART_REGISTRY) {
    $env:CHART_REGISTRY
} else {
    "oci://ghcr.io/YOUR_ORG_OR_USERNAME/charts"
}

$Version = if ($env:CHART_VERSION) {
    $env:CHART_VERSION
} else {
    "1.0.0"
}

$Charts = @(
    "_base",
    "_base-identity",
    "_base-frontend",
    "_infra-gateway",
    "_infra-eureka",
    "_infra-configserver",
    "_worker",
    "_scheduler",
    "_bff",
    "_websocket",
    "_batch-job",
    "_database-migration"
)

$PackageDir = Join-Path $env:TEMP "charts"
New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null

Write-Host "Packaging and publishing charts to $Registry"

foreach ($Chart in $Charts) {
    $ChartPath = Join-Path "charts" $Chart
    $PackagePath = Join-Path $PackageDir "$Chart-$Version.tgz"

    Write-Host "Packaging $ChartPath ..."
    helm package $ChartPath --version $Version --destination $PackageDir

    Write-Host "Pushing $Chart`:$Version ..."
    helm push $PackagePath $Registry
}

Write-Host "All charts published successfully!"

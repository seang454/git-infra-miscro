# publish-charts.ps1
# Packages and publishes all charts to an OCI registry.
# Run this in CI or from Windows PowerShell when git-infra-miscro changes.

$ErrorActionPreference = "Stop"

$Registry = if ($env:CHART_REGISTRY) {
    $env:CHART_REGISTRY
} else {
    "oci://ghcr.io/seang454/git-infra-miscro/charts"
}

$Version = if ($env:CHART_VERSION) {
    $env:CHART_VERSION
} else {
    "1.0.0"
}

$PackageDir = if ($env:CHART_PACKAGE_DIR) {
    $env:CHART_PACKAGE_DIR
} else {
    Join-Path $env:TEMP "charts"
}

$Charts = @(
    @{ Folder = "_base"; Package = "base" },
    @{ Folder = "_base-identity"; Package = "base-identity" },
    @{ Folder = "_base-frontend"; Package = "base-frontend" },
    @{ Folder = "_infra-gateway"; Package = "infra-gateway" },
    @{ Folder = "_infra-eureka"; Package = "infra-eureka" },
    @{ Folder = "_infra-configserver"; Package = "infra-configserver" },
    @{ Folder = "_worker"; Package = "worker" },
    @{ Folder = "_scheduler"; Package = "scheduler" },
    @{ Folder = "_bff"; Package = "bff" },
    @{ Folder = "_websocket"; Package = "websocket" },
    @{ Folder = "_batch-job"; Package = "batch-job" },
    @{ Folder = "_database-migration"; Package = "database-migration" }
)

New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null

Write-Host "Packaging and publishing charts to $Registry"

foreach ($Chart in $Charts) {
    $ChartPath = Join-Path "charts" $Chart.Folder
    $PackagePath = Join-Path $PackageDir "$($Chart.Package)-$Version.tgz"

    Write-Host "Packaging $ChartPath as $($Chart.Package) ..."
    helm package $ChartPath --version $Version --destination $PackageDir
    if ($LASTEXITCODE -ne 0) {
        throw "helm package failed for $($Chart.Folder)"
    }

    Write-Host "Pushing $($Chart.Package):$Version ..."
    helm push $PackagePath $Registry
    if ($LASTEXITCODE -ne 0) {
        throw "helm push failed for $($Chart.Package)"
    }
}

Write-Host "All charts published successfully!"

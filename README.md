# git-infra-miscro

Shared Helm chart templates for all ITP microservices.
Owned and maintained by the Platform/DevOps team.

This repository stores the source code for reusable Helm charts. CI/CD should
package these charts and publish them to a Helm OCI registry such as GitHub
Container Registry (GHCR). The `git-ops-miscro` repository references the
published chart versions.

It also stores reusable Dockerfile templates under
`dockerfile-shared-libray/`. Jenkins can use those templates when a scanned
service does not provide its own Dockerfile.

Recommended flow:

```text
git-infra-miscro GitHub repo
  -> CI packages charts
  -> CI pushes chart packages to GHCR
  -> git-ops-miscro references the GHCR chart versions
  -> Argo CD deploys the services
```

## Charts

| Chart | Used By |
|---|---|
| `base` | All backend microservices |
| `base-identity` | itp-identity-service |
| `base-frontend` | e-banking-front, next-shadcn-dashboard, front-bff |
| `infra-gateway` | gateway-server |
| `infra-eureka` | eurekaservice |
| `infra-configserver` | configserver |
| `worker` | background workers and queue consumers |
| `scheduler` | scheduled CronJob services |
| `bff` | backend-for-frontend services |
| `websocket` | realtime websocket services |
| `batch-job` | one-time Kubernetes Job workloads |
| `database-migration` | database migration Jobs such as Flyway or Liquibase |

## Dockerfile Shared Library

Dockerfile templates live in:

```text
dockerfile-shared-libray/resources/dockerfiles/
```

The Jenkins helper lives in:

```text
dockerfile-shared-libray/vars/dockerfileTemplate.groovy
```

The helper maps scanner `technology` values to templates. Example:

```groovy
def template = dockerfileTemplate(technology: params.TECHNOLOGY)
writeFile file: 'Dockerfile', text: libraryResource(template.resource)
```

Use the service Dockerfile if one exists. If it is missing, use the matching
platform template from this shared library.

## Jenkins Pipelines

This repo has three Jenkins pipelines.

### Deploy All Orchestrator

The single endpoint for Teamlife is:

```text
Jenkinsfile.deploy-all
```

Create one Jenkins job:

```text
Job name: deploy-all-microservices
Pipeline from SCM: git-infra-miscro
Script path: Jenkinsfile.deploy-all
```

Teamlife calls only this job. It triggers image builds in parallel, waits for
all builds to finish, collects their `image-result.json` artifacts, then calls
the GitOps promote pipeline once.

Parameters:

```text
ENVIRONMENT
SERVICES_JSON
BUILD_JOB_NAME
PROMOTE_JOB_NAME
GIT_OPS_REPO
GIT_OPS_BRANCH
```

Example `SERVICES_JSON`:

```json
[
  {
    "serviceName": "configserver",
    "sourceRepo": "https://github.com/seang454/project-services.git",
    "servicePath": "configserver",
    "technology": "spring-boot",
    "buildTool": "gradle",
    "imageRepo": "ghcr.io/seang454/configserver",
    "valuesKey": "infra-configserver",
    "wave": 0
  },
  {
    "serviceName": "customer-service",
    "sourceRepo": "https://github.com/seang454/project-services.git",
    "servicePath": "customer-service",
    "technology": "spring-boot",
    "buildTool": "gradle",
    "imageRepo": "ghcr.io/seang454/customer-service",
    "valuesKey": "base",
    "wave": 2
  }
]
```

### Build Image Pipeline

The reusable image build pipeline is stored at:

```text
Jenkinsfile
```

It expects Teamlife to pass one service at a time:

```text
SERVICE_NAME
SOURCE_REPO
SERVICE_PATH
TECHNOLOGY
BUILD_TOOL
IMAGE_REPO
IMAGE_TAG
```

The pipeline clones the source service, creates a Dockerfile from the shared
templates if one is missing, builds the image, pushes it to the registry, and
archives `image-result.json`.

Example build result:

```json
{
  "serviceName": "customer-service",
  "sourceRepo": "https://github.com/seang454/project-services.git",
  "servicePath": "customer-service",
  "technology": "spring-boot",
  "buildTool": "gradle",
  "imageRepo": "ghcr.io/seang454/customer-service",
  "imageTag": "build-25",
  "fullImage": "ghcr.io/seang454/customer-service:build-25"
}
```

Teamlife can run many build-image jobs in parallel.

### GitOps Promote Pipeline

The GitOps promotion pipeline is stored at:

```text
Jenkinsfile.gitops-promote
```

It expects Teamlife to pass all built image results in one JSON array:

```text
SERVICE_IMAGES_JSON
ENVIRONMENT
GIT_OPS_REPO
GIT_OPS_BRANCH
```

Each item also needs the GitOps metadata chosen by the scanner/UI:

```text
valuesKey
wave
```

Example promote input:

```json
[
  {
    "serviceName": "configserver",
    "sourceRepo": "https://github.com/seang454/project-services.git",
    "servicePath": "configserver",
    "technology": "spring-boot",
    "buildTool": "gradle",
    "imageRepo": "ghcr.io/seang454/configserver",
    "imageTag": "build-21",
    "valuesKey": "infra-configserver",
    "wave": 0
  },
  {
    "serviceName": "customer-service",
    "sourceRepo": "https://github.com/seang454/project-services.git",
    "servicePath": "customer-service",
    "technology": "spring-boot",
    "buildTool": "gradle",
    "imageRepo": "ghcr.io/seang454/customer-service",
    "imageTag": "build-25",
    "valuesKey": "base",
    "wave": 2
  }
]
```

The promote pipeline checks out `git-ops-miscro`, creates missing service
folders, reads default values from `charts/{chart}/values.yaml`, updates image
tags, and pushes commits in wave order:

```text
wave 0 commit and push
wave 1 commit and push
wave 2 commit and push
...
wave n commit and push
```

The wave value is dynamic. Teamlife can assign `0..n` based on the number of
detected services. The selected value is written to each service `app.yaml`:

```yaml
wave: "2"
```

Jenkins does not need Kubernetes access in this split. It only builds images and
writes GitOps desired state. Argo CD handles the actual Kubernetes deployment.

If the service does not already exist in `git-ops-miscro`, the pipeline creates
the GitOps service folder automatically:

```text
teams/itp/project-itp/{SERVICE_NAME}/
  Chart.yaml
  app.yaml
  environments/
    dev/values.yaml
    prod/values.yaml
```

The generated `Chart.yaml` depends on the selected platform chart from GHCR.
The generated environment values files are created from the selected infra
chart's default `values.yaml`, wrapped under the dependency chart name, then
updated with service-specific values such as image repository, image tag,
profile, replica count, and ingress host.

For example, if `VALUES_KEY=base`, Jenkins reads:

```text
charts/_base/values.yaml
```

and writes GitOps values like:

```yaml
base:
  deployments:
    api:
      image:
        repository: ghcr.io/seang454/customer-service
        tag: build-25
```

Required Jenkins plugins:

```text
Pipeline
Git
Docker Pipeline or Docker CLI on the agent
Pipeline Utility Steps
Credentials Binding
Copy Artifact
```

Required Jenkins credential:

```text
github-token
```

Use a GitHub username/password credential where the password is a GitHub PAT
with repository access and GHCR package push permissions.

Each chart includes a `values.yaml` file with shared defaults. These defaults
are packaged with the chart and published to GHCR together with the templates.
Environment-specific overrides stay in `git-ops-miscro`.

Use the chart that matches the service type:

| Service Type | Chart |
|---|---|
| Normal HTTP backend API | `base` |
| Identity/auth service | `base-identity` |
| Frontend app | `base-frontend` |
| API gateway | `infra-gateway` |
| Eureka service discovery | `infra-eureka` |
| Spring Cloud Config Server | `infra-configserver` |
| Queue consumer or background process | `worker` |
| Scheduled task | `scheduler` |
| Backend-for-frontend API | `bff` |
| Realtime websocket service | `websocket` |
| One-time job | `batch-job` |
| Database migration job | `database-migration` |

## Production Defaults

All charts include production-oriented settings in `values.yaml`:

```yaml
serviceAccount:
  create: true
  name: ""
  annotations: {}

imagePullSecrets: []
imagePullPolicy: IfNotPresent

podSecurityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  capabilities:
    drop:
      - ALL

nodeSelector: {}
tolerations: []
affinity: {}
```

Long-running workload charts also include optional PodDisruptionBudget and
NetworkPolicy resources:

```yaml
podDisruptionBudget:
  enabled: false
  minAvailable: 1

networkPolicy:
  enabled: false
  policyTypes:
    - Ingress
    - Egress
  ingress: []
  egress: []
```

Keep `networkPolicy.enabled` disabled until you define the ingress and egress
rules needed by the service. Enabling it with empty rules can block traffic.

Job-style charts (`scheduler`, `batch-job`, `database-migration`) include
ServiceAccount, security context, image pull, and scheduling controls, but do
not include PodDisruptionBudget because PDB is for long-running pods.

## Chart Type

These charts use:

```yaml
type: application
```

They are application charts because their `templates/` folders contain real
Kubernetes resources such as Deployments, Services, Ingresses, ConfigMaps, and
Secrets.

Do not use `type: library` for the current structure. Library charts are only
for helper templates that are called by another chart using `include`. The
service charts in `git-ops-miscro` do not currently have wrapper templates, so
the shared charts must render resources directly.

## Publish Charts

Linux/macOS:

```bash
export CHART_REGISTRY="oci://ghcr.io/seang454/git-infra-miscro/charts"
export CHART_VERSION="1.0.0"
bash scripts/publish-charts.sh
```

Windows PowerShell:

```powershell
$env:CHART_REGISTRY = "oci://ghcr.io/seang454/git-infra-miscro/charts"
$env:CHART_VERSION = "1.0.0"
.\scripts\publish-charts.ps1
```

## Adding a New Chart

1. Create a folder under `charts/`.
2. Add `Chart.yaml` with `type: application`.
3. Add `values.yaml` with safe shared defaults.
4. Add Kubernetes templates under `templates/`.
5. Run `publish-charts.sh` on Linux/macOS or `publish-charts.ps1` on Windows.
6. Reference the published chart in a `git-ops-miscro` service `Chart.yaml`.

# git-infra-miscro

Shared Helm chart templates for all ITP microservices.
Owned and maintained by the Platform/DevOps team.

This repository stores the source code for reusable Helm charts. CI/CD should
package these charts and publish them to a Helm OCI registry such as GitHub
Container Registry (GHCR). The `git-ops-miscro` repository references the
published chart versions.

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

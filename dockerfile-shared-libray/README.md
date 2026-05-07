# Dockerfile Shared Library

Reusable Dockerfile templates for services detected by the Teamlife scanner.

This folder is intentionally stored in `git-infra-miscro` because Docker build
standards are platform-owned infrastructure, just like the shared Helm charts.

## Usage

The scanner returns a `technology` value such as:

```yaml
technology: spring-boot
```

Jenkins selects a Dockerfile template from that value, writes it to the service
folder if the service does not already have a Dockerfile, then runs:

```bash
docker build -t IMAGE_TAG .
```

Recommended rule:

```text
If a service already has Dockerfile, use the service Dockerfile.
If Dockerfile is missing, use the matching platform template.
```

## Template Map

| Technology | Template |
|---|---|
| `spring-boot` | `spring-boot-gradle.Dockerfile` or `spring-boot-maven.Dockerfile` |
| `java-quarkus` | `java-quarkus.Dockerfile` |
| `java-micronaut` | `java-micronaut.Dockerfile` |
| `nextjs` | `nextjs.Dockerfile` |
| `nuxtjs` | `nuxtjs.Dockerfile` |
| `sveltekit` | `sveltekit.Dockerfile` |
| `astro` | `astro.Dockerfile` |
| `react-vite` | `react-vite.Dockerfile` |
| `angular` | `angular.Dockerfile` |
| `vue` | `vue.Dockerfile` |
| `nestjs` | `nestjs.Dockerfile` |
| `express-node` | `express-node.Dockerfile` |
| `python-fastapi` | `python-fastapi.Dockerfile` |
| `python-flask` | `python-flask.Dockerfile` |
| `python-django` | `python-django.Dockerfile` |
| `php-laravel` | `php-laravel.Dockerfile` |
| `php-symfony` | `php-symfony.Dockerfile` |
| `ruby-rails` | `ruby-rails.Dockerfile` |
| `go` | `go.Dockerfile` |
| `dotnet` | `dotnet.Dockerfile` |
| `rust-api` | `rust-api.Dockerfile` |

## Jenkins Example

```groovy
def template = dockerfileTemplate(
  technology: params.TECHNOLOGY,
  buildTool: params.BUILD_TOOL
)

dir("source/${params.SERVICE_PATH}") {
  if (!fileExists('Dockerfile')) {
    writeFile file: 'Dockerfile', text: libraryResource(template.resource)
  }

  sh "docker build -t ${params.IMAGE_TAG} ."
}
```

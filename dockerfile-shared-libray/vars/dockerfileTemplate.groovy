def call(Map args = [:]) {
    String technology = normalize(args.technology)
    String buildTool = normalize(args.buildTool)

    String resource

    switch (technology) {
        case 'spring-boot':
            resource = buildTool == 'maven'
                ? 'dockerfiles/spring-boot-maven.Dockerfile'
                : 'dockerfiles/spring-boot-gradle.Dockerfile'
            break

        case 'java-quarkus':
            resource = 'dockerfiles/java-quarkus.Dockerfile'
            break

        case 'java-micronaut':
            resource = 'dockerfiles/java-micronaut.Dockerfile'
            break

        case 'nextjs':
            resource = 'dockerfiles/nextjs.Dockerfile'
            break

        case 'nuxtjs':
            resource = 'dockerfiles/nuxtjs.Dockerfile'
            break

        case 'sveltekit':
            resource = 'dockerfiles/sveltekit.Dockerfile'
            break

        case 'astro':
            resource = 'dockerfiles/astro.Dockerfile'
            break

        case 'react-vite':
            resource = 'dockerfiles/react-vite.Dockerfile'
            break

        case 'angular':
            resource = 'dockerfiles/angular.Dockerfile'
            break

        case 'vue':
            resource = 'dockerfiles/vue.Dockerfile'
            break

        case 'nestjs':
            resource = 'dockerfiles/nestjs.Dockerfile'
            break

        case 'express-node':
            resource = 'dockerfiles/express-node.Dockerfile'
            break

        case 'python-fastapi':
            resource = 'dockerfiles/python-fastapi.Dockerfile'
            break

        case 'python-flask':
            resource = 'dockerfiles/python-flask.Dockerfile'
            break

        case 'python-django':
            resource = 'dockerfiles/python-django.Dockerfile'
            break

        case 'php-laravel':
            resource = 'dockerfiles/php-laravel.Dockerfile'
            break

        case 'php-symfony':
            resource = 'dockerfiles/php-symfony.Dockerfile'
            break

        case 'ruby-rails':
            resource = 'dockerfiles/ruby-rails.Dockerfile'
            break

        case 'go':
            resource = 'dockerfiles/go.Dockerfile'
            break

        case 'dotnet':
            resource = 'dockerfiles/dotnet.Dockerfile'
            break

        case 'rust-api':
            resource = 'dockerfiles/rust-api.Dockerfile'
            break

        default:
            error "No Dockerfile template is registered for technology '${technology}'."
    }

    return [
        technology: technology,
        buildTool: buildTool,
        resource: resource
    ]
}

private String normalize(Object value) {
    return (value ?: '').toString().trim().toLowerCase()
}

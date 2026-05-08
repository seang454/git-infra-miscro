pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        string(name: 'SERVICE_NAME', defaultValue: '', description: 'Service name, for example account-service')
        string(name: 'SOURCE_REPO', defaultValue: '', description: 'Source GitHub repo URL')
        string(name: 'SERVICE_PATH', defaultValue: '', description: 'Path to service inside repo. Empty means repo root')
        string(name: 'TECHNOLOGY', defaultValue: 'spring-boot', description: 'Scanner technology value')
        string(name: 'BUILD_TOOL', defaultValue: 'gradle', description: 'Build tool hint, used by spring-boot: gradle or maven')
        string(name: 'IMAGE_REPO', defaultValue: 'ghcr.io/seang454/service-name', description: 'Image repository without tag')
        string(name: 'IMAGE_TAG', defaultValue: '', description: 'Optional image tag. Empty uses build-{BUILD_NUMBER}')
    }

    stages {
        stage('Validate') {
            steps {
                script {
                    requireParam('SERVICE_NAME')
                    requireParam('SOURCE_REPO')
                    requireParam('IMAGE_REPO')
                    env.RESOLVED_IMAGE_TAG = params.IMAGE_TAG?.trim() ?: "build-${env.BUILD_NUMBER}"
                    env.FULL_IMAGE = "${params.IMAGE_REPO}:${env.RESOLVED_IMAGE_TAG}"
                }
            }
        }

        stage('Checkout Source') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh '''
                        rm -rf source
                        git clone "https://${GITHUB_USER}:${GITHUB_TOKEN}@${SOURCE_REPO#https://}" source
                    '''
                }
            }
        }

        stage('Prepare Dockerfile') {
            steps {
                script {
                    String serviceDir = serviceDirectory()
                    String dockerfilePath = "${serviceDir}/Dockerfile"

                    if (!fileExists(dockerfilePath)) {
                        String template = dockerfileTemplatePath(params.TECHNOLOGY, params.BUILD_TOOL)
                        echo "Dockerfile not found. Using platform template: ${template}"
                        sh "cp '${template}' '${dockerfilePath}'"
                    } else {
                        echo "Using service Dockerfile: ${dockerfilePath}"
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    dir(serviceDirectory()) {
                        sh "docker build -t '${FULL_IMAGE}' ."
                    }
                }
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh '''
                        echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USER}" --password-stdin
                        docker push "${FULL_IMAGE}"
                    '''
                }
            }
        }

        stage('Write Build Result') {
            steps {
                script {
                    Map result = [
                        serviceName: params.SERVICE_NAME,
                        sourceRepo : params.SOURCE_REPO,
                        servicePath: params.SERVICE_PATH,
                        technology : params.TECHNOLOGY,
                        buildTool  : params.BUILD_TOOL,
                        imageRepo  : params.IMAGE_REPO,
                        imageTag   : env.RESOLVED_IMAGE_TAG,
                        fullImage  : env.FULL_IMAGE
                    ]
                    writeJSON(file: 'image-result.json', json: result, pretty: 2)
                    archiveArtifacts artifacts: 'image-result.json', fingerprint: true
                    echo "IMAGE_RESULT_JSON=${groovy.json.JsonOutput.toJson(result)}"
                }
            }
        }
    }

    post {
        success {
            echo "Published ${FULL_IMAGE}"
        }
        always {
            sh 'docker logout ghcr.io || true'
        }
    }
}

void requireParam(String name) {
    if (!params[name]?.trim()) {
        error "Missing required parameter: ${name}"
    }
}

String serviceDirectory() {
    String path = params.SERVICE_PATH?.trim()
    return path ? "source/${path}" : 'source'
}

String dockerfileTemplatePath(String technology, String buildTool) {
    String normalizedTechnology = (technology ?: '').trim().toLowerCase()
    String normalizedBuildTool = (buildTool ?: '').trim().toLowerCase()
    String base = 'dockerfile-shared-libray/resources/dockerfiles'

    Map templates = [
        'java-quarkus'   : "${base}/java-quarkus.Dockerfile",
        'java-micronaut': "${base}/java-micronaut.Dockerfile",
        'nextjs'        : "${base}/nextjs.Dockerfile",
        'nuxtjs'        : "${base}/nuxtjs.Dockerfile",
        'sveltekit'     : "${base}/sveltekit.Dockerfile",
        'astro'         : "${base}/astro.Dockerfile",
        'react-vite'    : "${base}/react-vite.Dockerfile",
        'angular'       : "${base}/angular.Dockerfile",
        'vue'           : "${base}/vue.Dockerfile",
        'nestjs'        : "${base}/nestjs.Dockerfile",
        'express-node'  : "${base}/express-node.Dockerfile",
        'python-fastapi': "${base}/python-fastapi.Dockerfile",
        'python-flask'  : "${base}/python-flask.Dockerfile",
        'python-django' : "${base}/python-django.Dockerfile",
        'php-laravel'   : "${base}/php-laravel.Dockerfile",
        'php-symfony'   : "${base}/php-symfony.Dockerfile",
        'ruby-rails'    : "${base}/ruby-rails.Dockerfile",
        'go'            : "${base}/go.Dockerfile",
        'dotnet'        : "${base}/dotnet.Dockerfile",
        'rust-api'      : "${base}/rust-api.Dockerfile"
    ]

    if (normalizedTechnology == 'spring-boot') {
        return normalizedBuildTool == 'maven'
            ? "${base}/spring-boot-maven.Dockerfile"
            : "${base}/spring-boot-gradle.Dockerfile"
    }

    if (!templates.containsKey(normalizedTechnology)) {
        error "No Dockerfile template registered for technology: ${normalizedTechnology}"
    }

    return templates[normalizedTechnology]
}

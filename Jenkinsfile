pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'SERVICE_NAME', defaultValue: '', description: 'Service name, for example account-service')
        string(name: 'SOURCE_REPO', defaultValue: '', description: 'Source GitHub repo URL')
        string(name: 'SERVICE_PATH', defaultValue: '', description: 'Path to service inside repo. Empty means repo root')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'GitOps environment to update')
        string(name: 'TECHNOLOGY', defaultValue: 'spring-boot', description: 'Scanner technology value')
        string(name: 'BUILD_TOOL', defaultValue: 'gradle', description: 'Build tool hint, used by spring-boot: gradle or maven')
        string(name: 'IMAGE_REPO', defaultValue: 'ghcr.io/seang454/service-name', description: 'Image repository without tag')
        string(name: 'VALUES_KEY', defaultValue: 'base', description: 'Helm values root key: base, worker, base-frontend, etc.')
        string(name: 'GIT_OPS_REPO', defaultValue: 'https://github.com/seang454/git-ops-miscro.git', description: 'GitOps repo URL')
        string(name: 'GIT_OPS_BRANCH', defaultValue: 'main', description: 'GitOps branch')
    }

    environment {
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        FULL_IMAGE = "${params.IMAGE_REPO}:${IMAGE_TAG}"
    }

    stages {
        stage('Validate') {
            steps {
                script {
                    requireParam('SERVICE_NAME')
                    requireParam('SOURCE_REPO')
                    requireParam('IMAGE_REPO')
                    requireParam('VALUES_KEY')
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

        stage('Checkout GitOps') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh '''
                        rm -rf gitops
                        git clone --branch "${GIT_OPS_BRANCH}" "https://${GITHUB_USER}:${GITHUB_TOKEN}@${GIT_OPS_REPO#https://}" gitops
                    '''
                }
            }
        }

        stage('Update GitOps Image Tag') {
            steps {
                script {
                    String valuesPath = "gitops/teams/itp/project-itp/${params.SERVICE_NAME}/environments/${params.ENVIRONMENT}/values.yaml"
                    if (!fileExists(valuesPath)) {
                        error "Values file not found: ${valuesPath}"
                    }

                    Map values = readYaml(file: valuesPath)
                    updateImage(values, params.VALUES_KEY, params.IMAGE_REPO, env.IMAGE_TAG)
                    writeYaml(file: valuesPath, data: values, overwrite: true)
                }
            }
        }

        stage('Commit GitOps Change') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    dir('gitops') {
                        sh '''
                            git config user.email "jenkins@local"
                            git config user.name "jenkins"
                            git add "teams/itp/project-itp/${SERVICE_NAME}/environments/${ENVIRONMENT}/values.yaml"

                            if git diff --cached --quiet; then
                              echo "No GitOps changes to commit."
                            else
                              git commit -m "Deploy ${SERVICE_NAME} ${ENVIRONMENT} ${IMAGE_TAG}"
                              git push origin "${GIT_OPS_BRANCH}"
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Published ${FULL_IMAGE} and updated git-ops for ${params.SERVICE_NAME}/${params.ENVIRONMENT}"
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

void updateImage(Map values, String valuesKey, String imageRepo, String imageTag) {
    Map image = imageNode(values, valuesKey)
    image.repository = imageRepo
    image.tag = imageTag
}

Map imageNode(Map values, String valuesKey) {
    switch (valuesKey) {
        case 'base':
        case 'base-identity':
        case 'bff':
            return ensurePath(values, [valuesKey, 'deployments', 'api', 'image'])
        case 'base-frontend':
            return ensurePath(values, [valuesKey, 'deployments', 'app', 'image'])
        case 'infra-gateway':
            return ensurePath(values, [valuesKey, 'deployments', 'gateway', 'image'])
        case 'infra-eureka':
            return ensurePath(values, [valuesKey, 'deployments', 'eureka', 'image'])
        case 'infra-configserver':
            return ensurePath(values, [valuesKey, 'deployments', 'config', 'image'])
        case 'worker':
            return ensurePath(values, [valuesKey, 'workers', 'app', 'image'])
        case 'scheduler':
            return ensurePath(values, [valuesKey, 'schedules', 'app', 'image'])
        case 'websocket':
            return ensurePath(values, [valuesKey, 'deployments', 'ws', 'image'])
        case 'batch-job':
            return ensurePath(values, [valuesKey, 'jobs', 'app', 'image'])
        case 'database-migration':
            return ensurePath(values, [valuesKey, 'migrations', 'app', 'image'])
        default:
            error "Unsupported VALUES_KEY: ${valuesKey}"
    }
}

Map ensurePath(Map root, List<String> keys) {
    Map current = root
    keys.each { key ->
        if (!(current[key] instanceof Map)) {
            current[key] = [:]
        }
        current = current[key] as Map
    }
    return current
}

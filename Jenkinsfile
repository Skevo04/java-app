pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'petclinic'
        DOCKER_TAG = "${BUILD_NUMBER}"
        WORKSPACE_PATH = "${env.WORKSPACE}" // Jenkins workspace path

        DOCKER_REGISTRY = 'ghcr.io'
        GITHUB_USERNAME = 'skevo04'  // Replace with your GitHub username
        GITHUB_REPO = 'java-app'                   // Replace with your repository name
        GHCR_CREDENTIALS_ID = 'github_token'    // ← This MUST match your credential ID exactly

        BLUE_SERVER_IP = '192.168.64.7'
        GREEN_SERVER_IP = '192.168.64.6'
        SERVER_USER = 'ubuntu'
        SSH_CREDENTIALS_ID = 'prod_deploy'
        
        
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Frontend build') {
            steps {
                sh '''
                set -e
                chmod +x ./mvnw || true
                ./mvnw -B -Pcss -DskipTests generate-resources
                mkdir -p frontend-dist
                # copy generated static assets from build output (target/classes/static)
                if [ -d target/classes/static ]; then
                  cp -R target/classes/static/* frontend-dist/ || true
                elif [ -d src/main/resources/static ]; then
                  # fallback in case plugin wrote to source by mistake
                  cp -R src/main/resources/static/* frontend-dist/ || true
                fi
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'frontend-dist/**', allowEmptyArchive: true
                }
            }
        }

        stage('Backend build') {
            steps {
                sh '''
                set -e
                chmod +x ./mvnw || true
                # build backend artifact; do NOT activate -Pcss so frontend plugin won't run again
                ./mvnw -B -DskipTests clean package
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.build("${DOCKER_IMAGE}:latest")
                }
            }
        }
        
stage('Push to GitHub Packages') {
            environment {
                GHCR_TOKEN = credentials("${GHCR_CREDENTIALS_ID}")  // This references the credential
            }
            steps {
                script {
                    // Login to GitHub Container Registry
                    sh """
                        echo \"\$GHCR_TOKEN\" | docker login ${DOCKER_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin
                    """
                    
                    // Tag and push images
                    sh """
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:${DOCKER_TAG}
                        docker tag ${DOCKER_IMAGE}:latest ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                        docker push ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:${DOCKER_TAG}
                        docker push ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                    """
                }
            }
        }

        stage('Deploy Locally') {
            steps {
                sh 'docker-compose down || true'
                sh 'docker-compose up -d'
                echo 'Application deployed! Access at: http://localhost:8080'
            }
        }

      stage('Deploy Prod Blue') {
    
    steps {
        script {
            echo "Deploying to Production Blue environment"
            sshagent([SSH_CREDENTIALS_ID]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${BLUE_SERVER_IP} '
                        # Login to GitHub Container Registry
                        echo \"${GHCR_CREDENTIALS_ID}\" | docker login ${DOCKER_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin
                        
                        # Pull latest images
                        docker pull ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:${DOCKER_TAG}
                        docker pull ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                        
                        # Stop and remove existing containers
                        docker-compose down || true
                        
                        # Start new deployment
                        docker-compose up -d
                        
                        # Health check
                        sleep 30
                        docker ps
                        curl -f http://localhost:8080/health || exit 1
                    '
                """
            }
        }
    }
    post {
        success {
            echo "Production Blue deployment completed successfully"
        }
        failure {
            echo "Production Blue deployment failed"
            // Add rollback logic if needed
        }
    }
}

stage('Deploy Prod Green') {

    steps {
        script {
            echo "Deploying to Production Green environment"
            sshagent([SSH_CREDENTIALS_ID]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${GREEN_SERVER_IP} '
                        # Login to GitHub Container Registry
                        echo \"${GHCR_CREDENTIALS_ID}\" | docker login ${DOCKER_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin
                        
                        # Pull latest images
                        docker pull ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:${DOCKER_TAG}
                        docker pull ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                        
                        # Stop and remove existing containers
                        docker-compose down || true
                        
                        # Start new deployment
                        docker-compose up -d
                        
                        # Health check
                        sleep 30
                        docker ps
                        curl -f http://localhost:8080/health || exit 1
                    '
                """
            }
        }
    }
    post {
        success {
            echo "Production Green deployment completed successfully"
        }
        failure {
            echo "Production Green deployment failed"
        }
    }
}
    }
    
    
}
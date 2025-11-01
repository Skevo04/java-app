pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'petclinic'
        DOCKER_TAG = "${BUILD_NUMBER}"
        WORKSPACE_PATH = "${env.WORKSPACE}"

        DOCKER_REGISTRY = 'ghcr.io'
        GITHUB_USERNAME = 'skevo04'
        GITHUB_REPO = 'java-app'
        GHCR_CREDENTIALS_ID = 'github_token'

        BLUE_SERVER_IP = '192.168.64.9'
        GREEN_SERVER_IP = '192.168.64.6'
        LOADBALANCER_SERVER = '192.168.64.8'
        SERVER_USER = 'ubuntu'
        SSH_CREDENTIALS_ID = 'prod_deploy'
        SSH_CREDENTIALS_ID_LOADBALANCER = 'jenkins_loadbalancer'
        
        // Health check configuration
        HEALTH_CHECK_MAX_RETRIES = '10'
        HEALTH_CHECK_RETRY_DELAY = '10' // seconds
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
                if [ -d target/classes/static ]; then
                  cp -R target/classes/static/* frontend-dist/ || true
                elif [ -d src/main/resources/static ]; then
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

        stage('Deploy Locally') {
            steps {
                sh 'docker-compose down || true'
                sh 'docker-compose up -d'
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo "Performing health check on local deployment..."
                    
                    def healthCheckPassed = false
                    def retries = env.HEALTH_CHECK_MAX_RETRIES.toInteger()
                    
                    for (int i = 1; i <= retries; i++) {
                        try {
                            echo "Health check attempt ${i}/${retries}"
                            
                            // Test the application health
                            sh """
                                curl -f http://localhost:8080/actuator/health || \
                                curl -f http://localhost:8080 || \
                                exit 1
                            """
                            
                            echo "✅ Health check passed!"
                            healthCheckPassed = true
                            break
                            
                        } catch (Exception e) {
                            echo "⚠️ Health check attempt ${i} failed, waiting ${env.HEALTH_CHECK_RETRY_DELAY} seconds..."
                            if (i < retries) {
                                sleep env.HEALTH_CHECK_RETRY_DELAY.toInteger()
                            }
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        echo "❌ All health check attempts failed. Application is not healthy."
                        currentBuild.result = 'FAILURE'
                        error("Health check failed after ${retries} attempts")
                    }
                }
            }
        }

        stage('Push to GitHub Packages') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            environment {
                GHCR_TOKEN = credentials("${GHCR_CREDENTIALS_ID}")
            }
            steps {
                script {
                    echo "Health check passed - pushing image to registry"
                    
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

        // ... rest of your stages (Deploy Prod Blue, Green, Load Balancer) remain the same
        stage('Deploy Prod Blue') {
            environment {
                GHCR_TOKEN = credentials("${GHCR_CREDENTIALS_ID}")
            }
            steps {
                script {
                    echo "Deploying to Production Blue environment"
                    
                    // 1. Login and pull image on Jenkins agent
                    sh """
                        echo \"\${GHCR_TOKEN}\" | docker login ${DOCKER_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin
                        docker pull ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                    """
                    
                    // 2. Transfer and deploy directly
                    sshagent([SSH_CREDENTIALS_ID]) {
                        sh """
                            # Deploy on production server
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${BLUE_SERVER_IP} '
                                docker stop petclinic || true
                                docker rm petclinic || true
                            '
                            
                            docker save ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest | \
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${BLUE_SERVER_IP} docker load
                            
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${BLUE_SERVER_IP} '
                                docker run -d \
                                    --name petclinic \
                                    -p 8080:8080 \
                                    ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                                
                                sleep 30
                                echo "Container status:"
                                docker ps
                                echo "Health check:"
                                curl -f http://localhost:8080 || curl -f http://localhost:8080/actuator/health || exit 1
                                echo "✅ Blue deployment successful!"
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
                }
            }
        }

        stage('Deploy Prod Green') {
            environment {
                GHCR_TOKEN = credentials("${GHCR_CREDENTIALS_ID}")
            }
            steps {
                script {
                    echo "Deploying to Production Green environment"
                    
                    // 1. Login and pull image on Jenkins agent
                    sh """
                        echo \"\${GHCR_TOKEN}\" | docker login ${DOCKER_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin
                        docker pull ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                    """
                    
                    // 2. Transfer and deploy directly
                    sshagent([SSH_CREDENTIALS_ID]) {
                        sh """
                            # Deploy on production server
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${GREEN_SERVER_IP} '
                                docker stop petclinic || true
                                docker rm petclinic || true
                            '
                            
                            docker save ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest | \
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${GREEN_SERVER_IP} docker load
                            
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${GREEN_SERVER_IP} '
                                docker run -d \
                                    --name petclinic \
                                    -p 8080:8080 \
                                    ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                                
                                sleep 30
                                echo "Container status:"
                                docker ps
                                echo "Health check:"
                                curl -f http://localhost:8080 || curl -f http://localhost:8080/actuator/health || exit 1
                                echo "✅ Green deployment successful!"
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

        stage('Deploy Load Balancer') {
            steps {
                script {
                    echo "Deploying Nginx Load Balancer"
                    
                    sshagent([SSH_CREDENTIALS_ID_LOADBALANCER]) {
                        sh """
                            scp -o StrictHostKeyChecking=no /home/jenkins/nginx-loadbalancer.conf ${SERVER_USER}@${LOADBALANCER_SERVER}:/home/ubuntu/
                            scp -o StrictHostKeyChecking=no /home/jenkins/status-page.html ${SERVER_USER}@${LOADBALANCER_SERVER}:/home/ubuntu/
                            scp -o StrictHostKeyChecking=no /home/jenkins/workspace/final-project-build_main/docker-compose-loadbalancer.yml ${SERVER_USER}@${LOADBALANCER_SERVER}:/home/ubuntu/
                            
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${LOADBALANCER_SERVER} '
                                cd /home/ubuntu
                                docker-compose -f docker-compose-loadbalancer.yml down || true
                                docker-compose -f docker-compose-loadbalancer.yml up -d
                                echo "Load balancer deployed successfully!"
                                echo "🎯 Users should now access: http://${LOADBALANCER_SERVER}"
                                echo "📊 Status page: http://${LOADBALANCER_SERVER}/status"
                            '
                        """
                    }
                }
            }
            post {
                success {
                    echo "Load balancer deployed successfully!"
                    echo "Single access point: http://${LOADBALANCER_SERVER}"
                }
                failure {
                    echo "Load balancer deployment failed"
                }
            }
        }
    }
    
    post {
        always {
            echo "Cleaning up local deployment..."
            sh 'docker-compose down || true'
        }
    }
}
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
        LOADBALANCER_SERVER = '192.168.64.8'
        SERVER_USER = 'ubuntu'
        SSH_CREDENTIALS_ID = 'prod_deploy'
        SSH_CREDENTIALS_ID_LOADBALANCER = 'jenkins_loadbalancer'
        
        
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
                        # Stop and remove existing container if running
                        docker stop petclinic || true
                        docker rm petclinic || true
                    '
                    
                    # Transfer the Docker image directly
                    docker save ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest | \
                    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${BLUE_SERVER_IP} docker load
                    
                    # Start the deployment
                    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${BLUE_SERVER_IP} '
                        # Start new container
                        docker run -d \
                            --name petclinic \
                            -p 8080:8080 \
                            ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                        
                        # Health check
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
                        # Stop and remove existing container if running
                        docker stop petclinic || true
                        docker rm petclinic || true
                    '
                    
                    # Transfer the Docker image directly
                    docker save ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest | \
                    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${GREEN_SERVER_IP} docker load
                    
                    # Start the deployment
                    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${GREEN_SERVER_IP} '
                        # Start new container
                        docker run -d \
                            --name petclinic \
                            -p 8080:8080 \
                            ${DOCKER_REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}:latest
                        
                        # Health check
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
                            # Copy configuration files to load balancer server
                            scp -o StrictHostKeyChecking=no nginx-loadbalancer.conf ${SERVER_USER}@${LOADBALANCER_SERVER}:/home/ubuntu/
                            scp -o StrictHostKeyChecking=no docker-compose-loadbalancer.yml ${SERVER_USER}@${LOADBALANCER_SERVER}:/home/ubuntu/
                            
                            # Deploy load balancer
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${LOADBALANCER_SERVER} '
                                cd /home/ubuntu
                                echo "Stopping existing load balancer..."
                                docker-compose -f docker-compose-loadbalancer.yml down || true
                                
                                echo "Starting new load balancer..."
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
    
    
}
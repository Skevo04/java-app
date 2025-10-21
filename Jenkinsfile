pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'petclinic'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'your-registry-url' // Set your registry URL
        WORKSPACE_PATH = "${env.WORKSPACE}" // Jenkins workspace path
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
        
        stage('Deploy Locally') {
            steps {
                sh 'docker-compose down || true'
                sh 'docker-compose up -d'
                echo 'Application deployed! Access at: http://localhost:8080'
            }
        }


    }
    
    
}
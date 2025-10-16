pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'petclinic'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

    stage('Frontend (Maven - css profile)') {
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

        stage('Backend (Maven)') {
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
    }
}
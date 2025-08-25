pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }
    
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
        
        stage('Build') {
            steps {
                sh './mvnw clean compile'
            }
        }
        
        stage('Test') {
            steps {
                sh './mvnw test -Dtest="!PostgresIntegrationTests"'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Static Analysis') {
            steps {
                sh './mvnw spotbugs:check'
            }
        }
        
        stage('Package') {
            steps {
                sh './mvnw package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
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
        
        // stage('Deploy Locally') {
        //     steps {
        //         sh 'docker-compose down || true'
        //         sh 'docker-compose up -d'
        //         echo 'Application deployed! Access at: http://localhost:8080'
        //     }
        // }
    }
}
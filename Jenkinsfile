pipeline {
    agent any

    environment {
        AWS_REGION   = 'eu-north-1'
        ECR_REGISTRY = '552357224711.dkr.ecr.eu-north-1.amazonaws.com'
        EKS_CLUSTER  = 'devops-demo'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/rspatil08/microservices-devops_project.git'
            }
        }

        stage('Build') {
            steps {
                sh "docker build -t frontend:${env.BUILD_NUMBER} ./src/frontend"
            }
        }

        stage('Push to ECR') {
            steps {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                sh "docker tag frontend:${env.BUILD_NUMBER} ${ECR_REGISTRY}/frontend:${env.BUILD_NUMBER}"
                sh "docker push ${ECR_REGISTRY}/frontend:${env.BUILD_NUMBER}"
            }
        }

    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
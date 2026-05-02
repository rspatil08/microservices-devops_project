pipeline {
    agent any

    environment {
        AWS_REGION     = 'eu-north-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        EKS_CLUSTER    = 'devops-demo'
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/rspatil08/microservices-devops_project.git'
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('frontend') {
                    steps {
                        sh "docker build -t frontend:${env.BUILD_NUMBER} ./src/frontend"
                    }
                }

                /*stage('cartservice') {
                    steps {
                        sh "docker build -t cartservice:${env.BUILD_NUMBER} ./src/cartservice"
                    }
                }
                stage('productcatalogservice') {
                    steps {
                        sh "docker build -t productcatalogservice:${env.BUILD_NUMBER} ./src/productcatalogservice"
                    }
                }
                stage('currencyservice') {
                    steps {
                        sh "docker build -t currencyservice:${env.BUILD_NUMBER} ./src/currencyservice"
                    }
                }
                stage('paymentservice') {
                    steps {
                        sh "docker build -t paymentservice:${env.BUILD_NUMBER} ./src/paymentservice"
                    }
                }
                stage('shippingservice') {
                    steps {
                        sh "docker build -t shippingservice:${env.BUILD_NUMBER} ./src/shippingservice"
                    }
                }
                stage('emailservice') {
                    steps {
                        sh "docker build -t emailservice:${env.BUILD_NUMBER} ./src/emailservice"
                    }
                }
                stage('checkoutservice') {
                    steps {
                        sh "docker build -t checkoutservice:${env.BUILD_NUMBER} ./src/checkoutservice"
                    }
                }
                stage('recommendationservice') {
                    steps {
                        sh "docker build -t recommendationservice:${env.BUILD_NUMBER} ./src/recommendationservice"
                    }
                }
                stage('adservice') {
                    steps {
                        sh "docker build -t adservice:${env.BUILD_NUMBER} ./src/adservice"
                    }
                }
                stage('loadgenerator') {
                    steps {
                        sh "docker build -t loadgenerator:${env.BUILD_NUMBER} ./src/loadgenerator"
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"

                    def services = [
                        'frontend', 'cartservice', 'productcatalogservice',
                        'currencyservice', 'paymentservice', 'shippingservice',
                        'emailservice', 'checkoutservice', 'recommendationservice',
                        'adservice', 'loadgenerator'
                    ]

                    services.each { svc ->
                        sh "docker tag ${svc}:${env.BUILD_NUMBER} ${ECR_REGISTRY}/${svc}:${env.BUILD_NUMBER}"
                        sh "docker tag ${svc}:${env.BUILD_NUMBER} ${ECR_REGISTRY}/${svc}:latest"
                        sh "docker push ${ECR_REGISTRY}/${svc}:${env.BUILD_NUMBER}"
                        sh "docker push ${ECR_REGISTRY}/${svc}:latest"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh "aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION}"

                    def services = [
                        'frontend', 'cartservice', 'productcatalogservice',
                        'currencyservice', 'paymentservice', 'shippingservice',
                        'emailservice', 'checkoutservice', 'recommendationservice',
                        'adservice', 'loadgenerator'
                    ]

                    services.each { svc ->
                        sh "kubectl set image deployment/${svc} ${svc}=${ECR_REGISTRY}/${svc}:${env.BUILD_NUMBER} --namespace=default"
                    }
                }
            }
        }
    }*/

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed - check stage logs above.'
        }
    }
}
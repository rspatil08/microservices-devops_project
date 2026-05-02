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

        stage('Build Docker Images') {
            steps {
                script {
                    def services = [
                        'frontend', 'shoppingassistantservice', 'productcatalogservice',
                        'currencyservice', 'paymentservice', 'shippingservice',
                        'emailservice', 'checkoutservice', 'recommendationservice',
                        'adservice', 'loadgenerator'
                    ]
                    services.each { svc ->
                        sh "docker build -t ${svc}:${env.BUILD_NUMBER} ./src/${svc}"
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"

                    def services = [
                        'frontend', 'shoppingassistantservice', 'productcatalogservice',
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
                        'frontend', 'adservice', 'checkoutservice',
                        'currencyservice', 'emailservice', 'loadgenerator',
                        'paymentservice', 'productcatalogservice', 'recommendationservice',
                        'shippingservice', 'shoppingassistantservice'
                    ]

                    // Apply manifests first
                    sh """
                        for f in kubernetes-manifests/*.yaml; do
                            if [ "\$(basename \$f)" != "kustomization.yaml" ]; then
                                kubectl apply -f \$f --validate=false
                            fi
                        done
                    """

                    // Update each deployment to use YOUR ECR images
                    services.each { svc ->
                        sh """
                            kubectl set image deployment/${svc} \
                                server=${ECR_REGISTRY}/${svc}:${env.BUILD_NUMBER} \
                                --namespace=default \
                                --ignore-not-found=true 2>/dev/null || \
                            kubectl set image deployment/${svc} \
                                ${svc}=${ECR_REGISTRY}/${svc}:${env.BUILD_NUMBER} \
                                --namespace=default \
                                --ignore-not-found=true
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully - all services deployed!'
        }
        failure {
            echo 'Pipeline failed - check stage logs above.'
        }
    }
}
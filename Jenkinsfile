pipeline {
    agent any

    environment {
        AWS_REGION      = 'eu-north-1'
        AWS_ACCOUNT_ID  = credentials('aws-account-id')
        ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        EKS_CLUSTER     = 'devops-demo'
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
    }

    stages {

        // ── STAGE 1: CHECKOUT ──────────────────────────────────
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/rspatil08/microservices-devops_project.git'
            }
        }

        // ── STAGE 2: BUILD DOCKER IMAGES ───────────────────────
        stage('Build Docker Images') {
            parallel {
                stage('frontend') {
                    steps {
                        sh 'docker build -t frontend:${IMAGE_TAG} ./src/frontend'
                    }
                }
                stage('cartservice') {
                    steps {
                        sh 'docker build -t cartservice:${IMAGE_TAG} ./src/cartservice'
                    }
                }
                stage('productcatalogservice') {
                    steps {
                        sh 'docker build -t productcatalogservice:${IMAGE_TAG} ./src/productcatalogservice'
                    }
                }
                stage('currencyservice') {
                    steps {
                        sh 'docker build -t currencyservice:${IMAGE_TAG} ./src/currencyservice'
                    }
                }
                stage('paymentservice') {
                    steps {
                        sh 'docker build -t paymentservice:${IMAGE_TAG} ./src/paymentservice'
                    }
                }
                stage('shippingservice') {
                    steps {
                        sh 'docker build -t shippingservice:${IMAGE_TAG} ./src/shippingservice'
                    }
                }
                stage('emailservice') {
                    steps {
                        sh 'docker build -t emailservice:${IMAGE_TAG} ./src/emailservice'
                    }
                }
                stage('checkoutservice') {
                    steps {
                        sh 'docker build -t checkoutservice:${IMAGE_TAG} ./src/checkoutservice'
                    }
                }
                stage('recommendationservice') {
                    steps {
                        sh 'docker build -t recommendationservice:${IMAGE_TAG} ./src/recommendationservice'
                    }
                }
                stage('adservice') {
                    steps {
                        sh 'docker build -t adservice:${IMAGE_TAG} ./src/adservice'
                    }
                }
                stage('loadgenerator') {
                    steps {
                        sh 'docker build -t loadgenerator:${IMAGE_TAG} ./src/loadgenerator'
                    }
                }
            }
        }

        // ── STAGE 3: PUSH TO ECR ────────────────────────────────
        stage('Push to ECR') {
            steps {
                script {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''

                    def services = [
                        'frontend', 'cartservice', 'productcatalogservice',
                        'currencyservice', 'paymentservice', 'shippingservice',
                        'emailservice', 'checkoutservice', 'recommendationservice',
                        'adservice', 'loadgenerator'
                    ]

                    services.each { svc ->
                        sh """
                            docker tag ${svc}:${IMAGE_TAG} ${ECR_REGISTRY}/${svc}:${IMAGE_TAG}
                            docker tag ${svc}:${IMAGE_TAG} ${ECR_REGISTRY}/${svc}:latest
                            docker push ${ECR_REGISTRY}/${svc}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${svc}:latest
                        """
                    }
                }
            }
        }

        // ── STAGE 4: DEPLOY TO EKS ──────────────────────────────
        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                        aws eks update-kubeconfig \
                            --name ${EKS_CLUSTER} \
                            --region ${AWS_REGION}
                    '''

                    def services = [
                        'frontend', 'cartservice', 'productcatalogservice',
                        'currencyservice', 'paymentservice', 'shippingservice',
                        'emailservice', 'checkoutservice', 'recommendationservice',
                        'adservice', 'loadgenerator'
                    ]

                    services.each { svc ->
                        sh """
                            kubectl set image deployment/${svc} \
                                ${svc}=${ECR_REGISTRY}/${svc}:${IMAGE_TAG} \
                                --namespace=default
                        """
                    }
                }
            }
        }
    }

post {
        always {
            node('built-in') {
                sh '''
                    docker rmi $(docker images -q --filter "dangling=true") 2>/dev/null || true
                '''
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
    }
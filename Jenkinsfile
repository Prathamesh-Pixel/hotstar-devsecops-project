pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'RUN_SECURITY_SCANS', defaultValue: false, description: 'Skip scans to save resources.')
    }

    environment {
        DOCKER_IMAGE = "prathamesh1995/hotstar-clone"
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Docker Build') {
            steps {
                // Your successful build command
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Docker Push') {
            steps {
                // Ensure the 'docker' credentials ID exists in Jenkins Credentials!
                withCredentials([usernamePassword(credentialsId: 'docker', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Create namespace if it doesn't exist
                    sh "kubectl create namespace hotstar-namespace || true"
                    sh "kubectl apply -f deployment.yaml || echo 'Deployment failed - check file'"
                    sh "kubectl rollout restart deployment hotstar-deployment || echo 'Deployment not found'"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Check pods with: kubectl get pods -A"
        }
    }
}

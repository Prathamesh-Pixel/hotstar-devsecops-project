pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'RUN_SECURITY_SCANS', defaultValue: false, description: 'Skip heavy scans to save resources.')
    }

    environment {
        DOCKER_IMAGE = "prathamesh1995/hotstar-clone"
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Disk Cleanup') {
            steps {
                // Keep the workspace (for node_modules), but clear Docker junk
                sh "docker system prune -f || true"
            }
        }

        stage('Docker Build') {
            steps {
                // This uses your local node_modules from the VM
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    // This block MUST have the 'sh' commands inside it to work
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "echo \$PASS | docker login -u \$USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Ensure namespace exists and apply the deployment
                    sh "kubectl create namespace hotstar-namespace || true"
                    sh "kubectl apply -f deployment.yaml || echo 'Deployment file error'"
                    // Restart only if deployment exists
                    sh "kubectl rollout restart deployment hotstar-deployment || echo 'Not deployed yet'"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline complete. Check your app with: kubectl get pods -A"
        }
    }
}

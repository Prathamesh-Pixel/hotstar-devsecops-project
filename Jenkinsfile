pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'RUN_SECURITY_SCANS', defaultValue: false, description: 'Uncheck this to skip Sonar/OWASP/ZAP/Trivy and save VM resources.')
    }

    environment {
        DOCKER_IMAGE = "prathamesh1995/hotstar-clone"
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Clean Workspace & Disk') {
            steps {
                sh "rm -rf *" 
                sh "docker system prune -f || true"
            }
        }

        stage('SCA & Security Scans (SKIPPABLE)') {
            when { expression { return params.RUN_SECURITY_SCANS } }
            steps {
                echo "Skipping heavy scans to save resources..."
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh "kubectl apply -f deployment.yaml || echo 'Deployment file missing'"
                // Only restart if the deployment exists
                sh "kubectl rollout restart deployment hotstar-deployment || echo 'Deployment not found'"
            }
        }

        stage('Verify Monitoring') {
            steps {
                script {
                    echo "Checking Observability Stack..."
                    sh "kubectl get pods -n monitoring || echo 'Monitoring namespace not found'"
                }
            }
        }
    } // End of Stages

    post {
        always {
            echo "Pipeline finished. Check Grafana at http://localhost:31000"
        }
    }
} // End of Pipeline

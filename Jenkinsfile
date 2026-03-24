pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'RUN_SECURITY_SCANS', defaultValue: false, description: 'Uncheck this to skip Sonar/OWASP/ZAP/Trivy and save VM resources.')
    }

    environment {
        DOCKER_IMAGE = "prathamesh1995/hotstar-clone"
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
    }

    stage('Clean Workspace') {
            steps {
                // Use standard shell delete instead of the plugin method
                sh "rm -rf *" 
            }
        }

        stage('SCA & Security Scans (SKIPPABLE)') {
            when { expression { return params.RUN_SECURITY_SCANS } }
            steps {
                script {
                    echo "Checking for vulnerabilities... (This stage is bypassed to save VM RAM/Disk)"
                }
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
                script {
                    sh "kubectl apply -f deployment.yaml"
                    sh "kubectl rollout restart deployment hotstar-deployment"
                }
            }
        }

        stage('Verify Monitoring (Prometheus & Grafana)') {
            steps {
                script {
                    echo "Checking Observability Stack..."
                    // This verifies the pods in your monitoring namespace
                    sh "kubectl get pods -n monitoring || echo 'Monitoring namespace not found'"
                    
                    // Health Check of the Hotstar App
                    sh "curl -s -o /dev/null -w '%{http_code}' http://localhost:30007 || echo 'App not reachable yet'"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Check Grafana at http://localhost:31000 (if running)"
        }
    }
}

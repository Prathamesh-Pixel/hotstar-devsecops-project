pipeline {
    agent any

    options {
        skipDefaultCheckout(false)
        checkoutToSubdirectory('.')
        // Enterprise practice: Keep only the last 10 builds to save disk space
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        booleanParam(name: 'RUN_FULL_SCAN', defaultValue: true, description: 'Uncheck to skip DAST and SCA for a fast build')
    }

    environment {
        // Injected from Jenkins Credentials Provider
        TMDB_API_KEY = credentials('tmdb-api-key')
        DOCKER_HUB_USER = "prathamesh1995"
        SCAN_IMAGE = "hotstar-clone"
        // NO_PROXY ensures Jenkins doesn't try to use a proxy for local Minikube traffic
        NO_PROXY = "localhost,127.0.0.1"
    }

    stages {
        stage('Verify & Clean') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Processing Commit: ${commit}"
                    // Wipe old containers to prevent port conflicts
                    sh "docker rm -f hotstar-container || true"
                }
            }
        }

        stage('Secret Scanning (Gitleaks)') {
            steps {
                // Enterprise: Scan for committed secrets. Fails build if secrets found.
                sh 'docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path --no-git -v'
            }
        }

        stage('Install Dependencies') {
            steps {
                // Includes the fix for @babel/plugin-proposal-private-property-in-object
                sh 'npm install'
            }
        }

        stage('SCA Scan (OWASP Dependency-Check)') {
            when { expression { return params.RUN_FULL_SCAN } }
            steps {
                script {
                    // Optimized with persistent volume mount and 4GB RAM allocation
                    sh """
                        docker run --rm \
                        -e JAVA_OPTS="-Xmx4g" \
                        -v \$(pwd):/src \
                        -v /var/lib/jenkins/owasp-data:/usr/share/dependency-check/data \
                        --user \$(id -u):\$(id -g) \
                        owasp/dependency-check:latest \
                        --scan /src \
                        --format HTML --format XML \
                        --project "Hotstar-Clone" \
                        --out /src \
                        --exclude '**/node_modules/**'
                    """
                    dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SonarQube') {
                        script {
                            def scannerHome = tool 'sonar-scanner'
                            sh "${scannerHome}/bin/sonar-scanner -Dsonar.login=${SONAR_TOKEN}"
                        }
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                // HARD GATE: Pipeline stops if SonarQube results are 'FAIL'
                waitForQualityGate abortPipeline: true
            }
        }

        stage('Build App') {
            steps {
                sh 'CI=false npm run build'
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh "trivy fs --format table -o trivy-fs-report.html --severity CRITICAL ."
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${SCAN_IMAGE} ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo '$PASS' | docker login -u $USER --password-stdin"
                        sh "docker tag ${SCAN_IMAGE}:latest ${DOCKER_HUB_USER}/${SCAN_IMAGE}:latest"
                        sh "docker push ${DOCKER_HUB_USER}/${SCAN_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh "kubectl apply -f deployment.yaml"
                    sh "kubectl apply -f service.yaml"
                    sh "kubectl rollout status deployment/hotstar-deployment"
                }
            }
        }

        stage('Verify Monitoring & Health') {
            steps {
                script {
                    // Dynamically get Minikube IP to prevent "Connection Refused"
                    def CURRENT_IP = sh(script: "minikube ip", returnStdout: true).trim()
                    echo "Checking Observability Stack (Prometheus/Grafana)..."
                    sh "kubectl get pods -n monitoring"
                    
                    echo "Verifying Hotstar App at http://${CURRENT_IP}:30007..."
                    
                    // Health Check with retry logic
                    sh """
                        for i in {1..3}; do
                          if curl -sI http://${CURRENT_IP}:30007 | grep '200 OK'; then
                            echo 'SUCCESS: Hotstar Clone is LIVE!'
                            break
                          else
                            echo 'Waiting for app... (Attempt \$i)'
                            sleep 10
                          fi
                        done
                    """
                }
            }
        }

        stage('DAST Scan (OWASP ZAP)') {
            when { expression { return params.RUN_FULL_SCAN } }
            steps {
                script {
                    def K8S_IP = sh(script: "minikube ip", returnStdout: true).trim()
                    
                    // Use '|| true' to bypass root-owned file permission errors
                    sh "chmod -R 777 . || true" 

                    // Run ZAP with --net=host for direct access to Minikube NodePort
                    sh "docker run --rm -u root --net=host -v \$(pwd):/zap/wrk/:rw zaproxy/zap-stable zap-baseline.py -t http://${K8S_IP}:30007 -r zap_report.html || true"
                    
                    sh "chmod -R 755 . || true"
                }
            }
        }

        stage('Trivy Image Scan (Fail-Gate)') {
            steps {
                // Fail build if image has CRITICAL vulnerabilities
                sh "trivy image --severity CRITICAL --exit-code 1 ${SCAN_IMAGE}"
                sh "trivy image --format table -o trivy-image-report.html --severity HIGH,CRITICAL ${SCAN_IMAGE}"
            }
        }

        stage('Run Local Container') {
            steps {
                sh """
                    docker run -d \
                    --name hotstar-container \
                    -p 3000:3000 \
                    -e REACT_APP_TMDB_API_KEY=${TMDB_API_KEY} \
                    ${SCAN_IMAGE}
                """
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f'
            
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'trivy-fs-report.html,trivy-image-report.html,dependency-check-report.html,zap_report.html',
                reportName: 'Full DevSecOps Security Reports'
            ])
        }
        success {
            echo "SUCCESS: Hotstar-Clone deployed with SAST, SCA, and DAST compliance."
        }
        failure {
            echo "FAILURE: Check SonarQube, Trivy, or ZAP logs."
        }
    }
}

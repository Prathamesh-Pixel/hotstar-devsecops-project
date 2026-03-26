def clusterIP = ""
pipeline {
    agent any

    options {
        skipDefaultCheckout(false)
        checkoutToSubdirectory('.')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        booleanParam(name: 'RUN_FULL_SCAN', defaultValue: true, description: 'Uncheck to skip DAST and SCA for a fast build')
    }

    environment {
        TMDB_API_KEY = credentials('tmdb-api-key')
        DOCKER_HUB_USER = "prathamesh1995"
        SCAN_IMAGE = "hotstar-clone"
        NO_PROXY = "localhost,127.0.0.1"
    }

    stages {
        stage('Verify & Clean') {
            steps {
                script {
                    echo "--- STARTING FRESH: NO MINIKUBE COMMANDS ---"
                    sh "docker rm -f hotstar-container || true"
                    sh "chmod -R 777 . || true" 
                }
            }
        }

        stage('Secret Scanning (Gitleaks)') {
            steps {
                sh 'docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path --no-git -v'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('SCA Scan (OWASP Dependency-Check)') {
            when { 
                expression { return params.RUN_FULL_SCAN } 
            }
            steps {
                script {
                    sh """
                        docker run --rm --dns 8.8.8.8 \
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
                    // This tells Jenkins to parse the results for the dashboard
                    dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                }
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('SonarQube') { 
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        sh "${scannerHome}/bin/sonar-scanner" 
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                waitForQualityGate abortPipeline: true
            }
        }

        stage('Build App') {
            steps {
                sh 'CI=false npm run build'
            }
        }

        stage('Trivy File Scan') {
            steps {
                script {
                    sh "trivy fs --format table --timeout 15m --skip-dirs .scannerwork -o trivy-fs-report.html ."
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    sh "docker build -t ${SCAN_IMAGE} ."
                    withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
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
                    withEnv(['KUBECONFIG=/var/lib/jenkins/.kube/config']) {
                        sh 'kubectl apply -f deployment.yaml'
                        sh 'kubectl apply -f service.yaml'
                        
                        clusterIP = sh(
                            script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}'", 
                            returnStdout: true
                        ).trim()
                        
                        echo "Deployment successful on IP: ${clusterIP}"
                    }
                }
            }
        }

        stage('Verify Monitoring & Health') {
            steps {
                script {
                    echo "Checking Health for IP: ${clusterIP}"
                    sh "kubectl get pods -n monitoring || true"
                    
                    sh """
                        for i in {1..3}; do
                          if curl -sI http://${clusterIP}:30007 | grep '200 OK'; then
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
            // Added -v $(pwd):/zap/wrk/:rw and -u root to fix the report error
            sh "docker run --rm -v \$(pwd):/zap/wrk/:rw -u root -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://${clusterIP}:30007 -r zap_report.html || true"
        }
    }
}

        stage('Trivy Image Scan (Fail-Gate)') {
            steps {
                sh "trivy image --severity CRITICAL --exit-code 1 ${SCAN_IMAGE}"
                sh "trivy image --format table -o trivy-image-report.html --severity HIGH,CRITICAL ${SCAN_IMAGE}"
            }
        }

        stage('Run Local Container') {
            steps {
                sh "docker run -d --name hotstar-container -p 3000:3000 -e REACT_APP_TMDB_API_KEY=${TMDB_API_KEY} ${SCAN_IMAGE}"
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
    }
}

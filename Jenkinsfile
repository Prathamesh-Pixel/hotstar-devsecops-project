pipeline {
    agent any

    options {
        // This is the proper way to clean the workspace in Jenkins 
        skipDefaultCheckout(false)
        checkoutToSubdirectory('.')
    }

    environment {
        SCAN_IMAGE = "hotstar-clone"
    }

    stages {
        stage('Verify Current Commit') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Scanning current commit only: ${commit}"
                }
            }
        }

        stage('Secret Scanning (Gitleaks)') {
            steps {
                // Scans for hardcoded passwords/keys in your code
                // Using docker to avoid installing gitleaks binary on the agent
                sh 'docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path --no-git -v'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('SCA Scan (OWASP Dependency-Check)') {
            steps {
                // Scans your node_modules for known vulnerabilities
                dependencyCheck additionalArguments: '--scan ./ --format HTML --format XML', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // This injects the token from Jenkins credentials
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
                sh "docker rm -f hotstar-container || true"
                sh "docker build -t ${SCAN_IMAGE} ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image --format table -o trivy-image-report.html --severity HIGH,CRITICAL ${SCAN_IMAGE}"
            }
        }

        stage('Run Container') {
            steps {
                sh "docker run -d --name hotstar-container -p 3000:3000 ${SCAN_IMAGE}"
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
                reportFiles: 'trivy-fs-report.html, trivy-image-report.html, dependency-check-report.html',
                reportName: 'Security & Vulnerability Reports'
            ])
        }
    }

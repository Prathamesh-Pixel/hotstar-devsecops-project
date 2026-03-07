pipeline {
    agent any

    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        def scannerExecutable = sh(script: "find ${scannerHome} -name sonar-scanner -type f", returnStdout: true).trim()
                        
                        if (scannerExecutable) {
                            sh "chmod +x ${scannerExecutable}"
                            sh "${scannerExecutable}"
                        } else {
                            error "Sonar-scanner executable not found. Check Tool configuration."
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
                // Checks your code & libraries BEFORE building
                sh "trivy fs --format table -o trivy-fs-report.html --severity CRITICAL ."
            }
        }
                    
        stage('Docker Build') {
            steps {
                sh 'docker rm -f hotstar-container || true'
                sh 'docker build -t hotstar-clone .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                // Checks the final Docker image AFTER building
                sh "trivy image --format table -o trivy-image-report.html --severity HIGH,CRITICAL hotstar-clone"
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker run -d --name hotstar-container -p 3000:3000 hotstar-clone'
            }
        }
    }
    
    post {
        always {
            // Keep your server clean
            sh 'docker image prune -f'
            
            // This publishes your Trivy reports so you can see them in Jenkins
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'trivy-fs-report.html, trivy-image-report.html',
                reportName: 'Trivy Security Reports'
            ])
        }
    }
}

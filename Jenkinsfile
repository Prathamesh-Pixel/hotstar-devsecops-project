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
                    error "Sonar-scanner executable not found in ${scannerHome}. Please check Tool configuration."
                }
            }
        }
    }
}

        stage("Quality Gate") {
            steps {
                // This waits for SonarQube to report back. 
                // If the code is "Bad", the pipeline stops here.
                waitForQualityGate abortPipeline: true
            }
        }
        
        stage('Build App') {
            steps {
                sh 'CI=false npm run build'
            }
        }

        stages {
        // ... (Checkout, NPM Install, SonarQube, Quality Gate)

        stage('Trivy FS Scan') {
            steps {
                // Checks your code & libraries BEFORE building
                sh "trivy fs --format table -o trivy-fs-report.html --severity CRITICAL ."
            }
        }
                    
        stage('Docker Build') {
            steps {
                // Stops/Removes old container so the new one doesn't fail on port 3000
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
            // Keeps your server clean by removing unused build images
            sh 'docker image prune -f'
        }
    }
}
}    

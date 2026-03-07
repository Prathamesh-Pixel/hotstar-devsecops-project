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
                // 'SonarQube' must match the name in Manage Jenkins > System
                withSonarQubeEnv('SonarQube') {
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        // It will automatically find your sonar-project.properties file
                        sh "${scannerHome}/bin/sonar-scanner"
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

        stage('Docker Build') {
            steps {
                // Stops/Removes old container so the new one doesn't fail on port 3000
                sh 'docker rm -f hotstar-container || true'
                sh 'docker build -t hotstar-clone .'
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

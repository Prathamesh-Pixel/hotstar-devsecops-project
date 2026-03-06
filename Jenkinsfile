pipeline {
    agent any

    stages {
        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Build App') {
            steps {
                sh 'CI=false npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t hotstar-clone .'
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker run -d -p 3000:3000 hotstar-clone'
            }
        }

    }
}

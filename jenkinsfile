pipeline {
    agent any

    stages {

        stage('Clone Repository') {
            steps {
                git
'https://github.com/Prathamesh-Pixel/hotstar-devsecops-project.git
            }
     }
     stage('Install Dependencies') {
         steps {
             sh 'npm install'
         }
     }

         stage('Build App') {
             steps {
                 sh 'npm run build'
                 }
         }

         stage('Docker Build') {
             steps {
                 sh 'docker build -t hotstar-clone .'
                 }
         }

         stage('Run Container') {
             steps {
                 sh 'docker run -d -p 3000:3000 hoststar-clone'
                 }
         }
     }
}

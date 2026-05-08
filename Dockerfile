pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Mubashir3344/assignment-2.git'
            }
        }

        stage('Check Docker') {
            steps {
                sh '''
                    docker --version
                    docker compose version
                '''
            }
        }

        stage('Containerized Build') {
            steps {
                sh '''
                    docker compose -f docker-compose.jenkins.yml build
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker compose -f docker-compose.jenkins.yml up -d
                '''
            }
        }
    }

    post {
        always {
            sh '''
                docker compose -f docker-compose.jenkins.yml stop || true
                docker compose -f docker-compose.jenkins.yml rm -f || true
            '''
        }

        success {
            echo 'Pipeline completed successfully!'
        }

        failure {
            echo 'Build/deployment pipeline failed.'
        }
    }
}

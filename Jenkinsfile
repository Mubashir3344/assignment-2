pipeline {
  agent any

  environment {
    REPO_URL = 'https://github.com/Mubashir3344/assignment-2.git'
    COMPOSE_FILE = 'docker-compose.jenkins.yml'
    API_IMAGE = 'mubashirhassan/assignment2-api'
    WEB_IMAGE = 'mubashirhassan/assignment2-web'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: "${REPO_URL}"
      }
    }

    stage('Containerized Build (Code Volume)') {
      steps {
        sh 'docker compose -f ${COMPOSE_FILE} run --rm web_builder sh -lc "npm ci && npm run build"'
        sh 'docker compose -f ${COMPOSE_FILE} run --rm api_builder sh -lc "cd server && npm ci && npx prisma generate"'
      }
    }

    stage('Docker Image Build') {
      steps {
        script {
          docker.build("${API_IMAGE}:${BUILD_NUMBER}", '-f server/Dockerfile ./server')
          docker.build("${WEB_IMAGE}:${BUILD_NUMBER}", '-f Dockerfile .')
        }
      }
    }

    stage('Tag Latest') {
      steps {
        sh 'docker tag ${API_IMAGE}:${BUILD_NUMBER} ${API_IMAGE}:latest'
        sh 'docker tag ${WEB_IMAGE}:${BUILD_NUMBER} ${WEB_IMAGE}:latest'
      }
    }
  }

  post {
    always {
      sh 'docker compose -f ${COMPOSE_FILE} down -v || true'
      sh 'docker image prune -f || true'
    }
    success {
      echo 'Build pipeline completed successfully.'
    }
    failure {
      echo 'Build pipeline failed. Check stage logs.'
    }
  }
}

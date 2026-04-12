pipeline {
  agent any

  triggers {
    githubPush()
    pollSCM('H/2 * * * *')
  }

  environment {
    REPO_URL = 'https://github.com/Mubashir3344/assignment-2.git'
    COMPOSE_FILE = 'docker-compose.jenkins.yml'
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

    stage('Deploy Part II (Ports 4000-4001)') {
      steps {
        sh '''
          echo "Stopping previous Part II deployment..."
          docker compose -f docker-compose-part2.yml down -v || true
          
          echo "Starting Part II services on ports 4000 (web) and 4001 (api)..."
          export NEXTAUTH_SECRET=jenkins-part2-secret-2026
          export NEXT_PUBLIC_API_BASE_URL=http://3.101.109.184:4001
          export INTERNAL_API_BASE_URL=http://api-part2:3001
          
          docker compose -f docker-compose-part2.yml up -d
          
          echo "Waiting for services to be ready..."
          sleep 10
          
          echo "Part II Deployment Status:"
          docker compose -f docker-compose-part2.yml ps
          
          echo "Part II Application URLs:"
          echo "Web App: http://3.101.109.184:4000"
          echo "API: http://3.101.109.184:4001"
        '''
      }
    }
  }

  post {
    always {
      sh 'docker compose -f ${COMPOSE_FILE} down -v || true'
    }
    success {
      echo 'Build and deployment pipeline completed successfully.'
      echo 'Part II is now running on:'
      echo '  Web: http://3.101.109.184:4000'
      echo '  API: http://3.101.109.184:4001'
    }
    failure {
      echo 'Build/deployment pipeline failed. Check stage logs.'
    }
  }
}

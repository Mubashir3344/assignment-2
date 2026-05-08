pipeline {
  agent any

  triggers {
    githubPush()
    pollSCM('H/2 * * * *')
  }

  environment {
    REPO_URL = 'https://github.com/Mubashir3344/assignment-2.git'
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

    stage('Check Docker') {
      steps {
        sh '''
          docker --version
          docker compose version
        '''
      }
    }

    stage('Build via Docker Compose') {
      steps {
        sh '''
          echo "Starting CI build..."

          docker compose run --rm \
            -e DATABASE_URL="mysql://singitronic_user:singitronic_local_2026@db_ci:3306/singitronic_nextjs_ci" \
            -e NEXTAUTH_SECRET="jenkins-part2-secret-2026" \
            -e NEXTAUTH_URL="http://localhost:4000" \
            -e NEXT_PUBLIC_API_BASE_URL="http://localhost:4001" \
            -e INTERNAL_API_BASE_URL="http://api-part2:3001" \
            web_builder

          docker compose run --rm api_builder
        '''
      }
    }

    stage('Deploy Part II (Ports 4000-4001)') {
      steps {
        sh '''
          echo "Stopping old deployment..."
          docker compose -f docker-compose-part2.yml down || true

          echo "Starting new deployment..."

          docker compose -f docker-compose-part2.yml up -d

          sleep 20

          API_RUNNING=$(docker inspect --format='{{.State.Running}}' singitronic-api-part2 2>/dev/null || echo "false")
          WEB_RUNNING=$(docker inspect --format='{{.State.Running}}' singitronic-web-part2 2>/dev/null || echo "false")

          if [ "$API_RUNNING" != "true" ] || [ "$WEB_RUNNING" != "true" ]; then
            echo "Containers failed"
            docker compose -f docker-compose-part2.yml ps || true
            docker compose -f docker-compose-part2.yml logs --tail=100 api-part2 web-part2 || true
            exit 1
          fi

          echo "Deployment successful"
        '''
      }
    }
  }

  post {

    always {
      sh '''
        docker compose -f docker-compose.jenkins.yml stop web_builder api_builder db_ci || true
        docker compose -f docker-compose.jenkins.yml rm -f web_builder api_builder db_ci || true
      '''
    }

    success {
      echo 'Pipeline SUCCESS'
      echo 'Web: http://3.101.109.184:4000'
      echo 'API: http://3.101.109.184:4001'
    }

    failure {
      echo 'Pipeline FAILED - check logs'
    }
  }
}

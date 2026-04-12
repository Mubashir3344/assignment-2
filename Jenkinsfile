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

    stage('Prepare Docker CLI') {
      steps {
        sh '''
          if ! command -v docker >/dev/null 2>&1; then
            apt-get update
            apt-get install -y docker.io docker-compose
          fi
          if ! command -v docker-compose >/dev/null 2>&1; then
            apt-get update
            apt-get install -y docker-compose
          fi
          docker --version
          docker-compose --version
        '''
      }
    }

    stage('Containerized Build (Code Volume)') {
      steps {
        sh '''
          export HOST_WORKSPACE_PATH=/home/ubuntu/assignment-2
          docker-compose -f ${COMPOSE_FILE} run --rm web_builder sh -lc 'export DATABASE_URL="mysql://singitronic_user:singitronic_local_2026@db_ci:3306/singitronic_nextjs_ci?sslmode=disabled" NEXTAUTH_SECRET="jenkins-part2-secret-2026" NEXTAUTH_URL="http://localhost:4000" NEXT_PUBLIC_API_BASE_URL="http://localhost:4001" INTERNAL_API_BASE_URL="http://api-part2:3001"; if [ -f package-lock.json ]; then npm ci; else npm install; fi && npm run build'
        '''
        sh '''
          export HOST_WORKSPACE_PATH=/home/ubuntu/assignment-2
          docker-compose -f ${COMPOSE_FILE} run --rm api_builder sh -lc 'cd server && if [ -f package-lock.json ]; then npm ci; else npm install; fi && npx prisma generate'
        '''
      }
    }

    stage('Deploy Part II (Ports 4000-4001)') {
      steps {
        sh '''
          export HOST_WORKSPACE_PATH=/home/ubuntu/assignment-2
          echo "Stopping previous Part II deployment..."
          docker-compose -f docker-compose-part2.yml down || true
          
          echo "Starting Part II services on ports 4000 (web) and 4001 (api)..."
          export NEXTAUTH_SECRET=jenkins-part2-secret-2026
          export NEXT_PUBLIC_API_BASE_URL=http://3.101.109.184:4001
          export INTERNAL_API_BASE_URL=http://api-part2:3001
          
          docker-compose -f docker-compose-part2.yml up -d
          
          echo "Waiting for services to be healthy..."
          API_READY=0
          WEB_READY=0
          for i in $(seq 1 24); do
            if curl -fsS http://localhost:4001/health >/dev/null 2>&1; then
              API_READY=1
            fi
            if curl -fsS http://localhost:4000 >/dev/null 2>&1; then
              WEB_READY=1
            fi
            if [ "$API_READY" -eq 1 ] && [ "$WEB_READY" -eq 1 ]; then
              echo "Part II services are reachable."
              break
            fi
            echo "Readiness attempt $i/24 -> api: $API_READY, web: $WEB_READY"
            sleep 5
          done

          if [ "$API_READY" -ne 1 ] || [ "$WEB_READY" -ne 1 ]; then
            echo "Part II services did not become reachable in time."
            docker-compose -f docker-compose-part2.yml ps || true
            docker-compose -f docker-compose-part2.yml logs --tail=120 api-part2 web-part2 || true
            exit 1
          fi
          
          echo "Part II Deployment Status:"
          docker-compose -f docker-compose-part2.yml ps
          
          echo "Part II Application URLs:"
          echo "Web App: http://3.101.109.184:4000"
          echo "API: http://3.101.109.184:4001"
        '''
      }
    }
  }

  post {
    always {
      sh '''
        docker-compose -f ${COMPOSE_FILE} stop web_builder api_builder db_ci || true
        docker-compose -f ${COMPOSE_FILE} rm -f web_builder api_builder db_ci || true
      '''
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

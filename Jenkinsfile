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

    stage('Check Docker') {
      steps {
        sh '''
          docker --version
          docker compose version
        '''
      }
    }

    stage('Containerized Build (Code Volume)') {
      steps {

        sh '''
          export HOST_WORKSPACE_PATH=/home/ubuntu/assignment-2

          docker compose -f ${COMPOSE_FILE} run --rm web_builder sh -lc '
            export DATABASE_URL="mysql://singitronic_user:singitronic_local_2026@db_ci:3306/singitronic_nextjs_ci"
            export NEXTAUTH_SECRET="jenkins-part2-secret-2026"
            export NEXTAUTH_URL="http://localhost:4000"
            export NEXT_PUBLIC_API_BASE_URL="http://localhost:4001"
            export INTERNAL_API_BASE_URL="http://api-part2:3001"

            if [ -f package-lock.json ]; then
              npm ci
            else
              npm install
            fi

            npm run build
          '
        '''

        sh '''
          export HOST_WORKSPACE_PATH=/home/ubuntu/assignment-2

          docker compose -f ${COMPOSE_FILE} run --rm api_builder sh -lc '
            cd server

            if [ -f package-lock.json ]; then
              npm ci
            else
              npm install
            fi

            npx prisma generate
          '
        '''
      }
    }

    stage('Deploy Part II (Ports 4000-4001)') {
      steps {

        sh '''
          export HOST_WORKSPACE_PATH=/home/ubuntu/assignment-2

          echo "Stopping previous deployment..."
          docker compose -f docker-compose-part2.yml down || true

          echo "Starting services..."

          export NEXTAUTH_SECRET=jenkins-part2-secret-2026
          export NEXT_PUBLIC_API_BASE_URL=http://3.101.109.184:4001
          export INTERNAL_API_BASE_URL=http://api-part2:3001

          docker compose -f docker-compose-part2.yml up -d

          echo "Waiting for containers..."
          sleep 20

          API_RUNNING=$(docker inspect --format='{{.State.Running}}' singitronic-api-part2 2>/dev/null || echo "false")
          WEB_RUNNING=$(docker inspect --format='{{.State.Running}}' singitronic-web-part2 2>/dev/null || echo "false")

          if [ "$API_RUNNING" != "true" ] || [ "$WEB_RUNNING" != "true" ]; then
            echo "Containers failed to start."

            docker compose -f docker-compose-part2.yml ps || true
            docker compose -f docker-compose-part2.yml logs --tail=120 api-part2 web-part2 || true

            exit 1
          fi

          echo "Deployment Status:"
          docker compose -f docker-compose-part2.yml ps

          echo "Application URLs:"
          echo "Web App: http://3.101.109.184:4000"
          echo "API: http://3.101.109.184:4001"
        '''
      }
    }
  }

  post {

    always {

      sh '''
        docker compose -f ${COMPOSE_FILE} stop web_builder api_builder db_ci || true

        docker compose -f ${COMPOSE_FILE} rm -f web_builder api_builder db_ci || true
      '''
    }

    success {
      echo 'Build and deployment pipeline completed successfully.'

      echo 'Part II is running on:'
      echo 'Web: http://3.101.109.184:4000'
      echo 'API: http://3.101.109.184:4001'
    }

    failure {
      echo 'Build/deployment pipeline failed. Check stage logs.'
    }
  }
}

pipeline {
  agent any

  triggers {
    githubPush()
    pollSCM('H/2 * * * *')
  }

  environment {
    REPO_URL      = 'https://github.com/Mubashir3344/assignment-2.git'
    TEST_REPO_URL = 'https://github.com/mubashir3344/test-cases.git'
    COMPOSE_FILE  = 'docker-compose.jenkins.yml'
    APP_URL       = 'http://13.51.242.231'
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

          docker compose -f ${COMPOSE_FILE} run --rm \
            -e DATABASE_URL="mysql://singitronic_user:singitronic_local_2026@db_ci:3306/singitronic_nextjs_ci" \
            -e NEXTAUTH_SECRET="jenkins-part2-secret-2026" \
            -e NEXTAUTH_URL="http://localhost:4000" \
            -e NEXT_PUBLIC_API_BASE_URL="http://localhost:4001" \
            -e INTERNAL_API_BASE_URL="http://api-part2:3001" \
            web_builder

          docker compose -f ${COMPOSE_FILE} run --rm api_builder
        '''
      }
    }

    stage('Deploy Part II (Ports 80 / 4001)') {
      steps {
        sh '''
          echo "Stopping previous deployment..."
          docker compose -f docker-compose-part2.yml down || true

          echo "Starting new deployment..."
          docker compose -f docker-compose-part2.yml up -d

          sleep 25

          API_RUNNING=$(docker inspect --format='{{.State.Running}}' singitronic-api-part2 2>/dev/null || echo "false")
          WEB_RUNNING=$(docker inspect --format='{{.State.Running}}' singitronic-web-part2 2>/dev/null || echo "false")

          if [ "$API_RUNNING" != "true" ] || [ "$WEB_RUNNING" != "true" ]; then
            echo "Containers failed to start"
            docker compose -f docker-compose-part2.yml ps || true
            docker compose -f docker-compose-part2.yml logs --tail=100 api-part2 web-part2 || true
            exit 1
          fi

          echo "Deployment successful!"
          echo "Web: ${APP_URL}"
        '''
      }
    }

    stage('Run Selenium Tests') {
      steps {
        sh '''
          echo "=== Cloning test-cases repository ==="
          rm -rf selenium-tests
          git clone ${TEST_REPO_URL} selenium-tests

          echo "=== Building Selenium test Docker image ==="
          docker build --no-cache -t singitronic-selenium-tests:latest selenium-tests/

          echo "=== Running Selenium tests ==="
          mkdir -p test-results
          docker run --rm \
            --network host \
            -e APP_URL=${APP_URL} \
            -v ${WORKSPACE}/test-results:/app/test-results \
            singitronic-selenium-tests:latest
          EXIT_CODE=$?

          echo "=== Docker exit code: ${EXIT_CODE} ==="
          echo "=== Contents of test-results: ==="
          ls -la test-results/ || echo "test-results directory is empty or missing"
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'test-results/results.xml'
          archiveArtifacts artifacts: 'test-results/report.html', allowEmptyArchive: true
        }
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
      script {
        def committerEmail = sh(
          script: "git log -1 --pretty=format:'%ae'",
          returnStdout: true
        ).trim()
        emailext(
          to: committerEmail,
          subject: "[Jenkins] BUILD SUCCESS - ${JOB_NAME} #${BUILD_NUMBER}",
          body: """
<html><body>
<h2 style="color:green;">&#10003; Jenkins Pipeline: SUCCESS</h2>
<table border="1" cellpadding="6" cellspacing="0">
  <tr><td><b>Job</b></td><td>${JOB_NAME}</td></tr>
  <tr><td><b>Build</b></td><td>#${BUILD_NUMBER}</td></tr>
  <tr><td><b>Triggered by</b></td><td>${committerEmail}</td></tr>
  <tr><td><b>Console</b></td><td><a href="${BUILD_URL}">${BUILD_URL}</a></td></tr>
  <tr><td><b>App URL</b></td><td><a href="${APP_URL}">${APP_URL}</a></td></tr>
</table>
<p>The full Selenium HTML test report is attached to this email.</p>
</body></html>
          """,
          mimeType: 'text/html',
          attachmentsPattern: 'test-results/report.html'
        )
      }
      echo 'Pipeline SUCCESS'
    }

    failure {
      script {
        def committerEmail = sh(
          script: "git log -1 --pretty=format:'%ae'",
          returnStdout: true
        ).trim()
        emailext(
          to: committerEmail,
          subject: "[Jenkins] BUILD FAILED - ${JOB_NAME} #${BUILD_NUMBER}",
          body: """
<html><body>
<h2 style="color:red;">&#10007; Jenkins Pipeline: FAILED</h2>
<table border="1" cellpadding="6" cellspacing="0">
  <tr><td><b>Job</b></td><td>${JOB_NAME}</td></tr>
  <tr><td><b>Build</b></td><td>#${BUILD_NUMBER}</td></tr>
  <tr><td><b>Triggered by</b></td><td>${committerEmail}</td></tr>
  <tr><td><b>Console</b></td><td><a href="${BUILD_URL}">${BUILD_URL}</a></td></tr>
</table>
<p>Check the console output for details.</p>
</body></html>
          """,
          mimeType: 'text/html',
          attachmentsPattern: 'test-results/report.html'
        )
      }
      echo 'Pipeline FAILED - check logs'
    }
  }
}
EOF

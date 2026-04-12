# Part II Report: Containerized Automation Pipeline with Jenkins (AWS EC2)

## 1. Objective

The objective of Part II was to configure Jenkins on AWS EC2 and automate the build phase of the same web application used in Part I.

Achieved outcomes:
- Jenkins installed and configured on EC2.
- GitHub repository integrated with Jenkins.
- Webhook-based trigger configured.
- Jenkins pipeline created using Git, Pipeline, and Docker Pipeline plugins.
- Build phase executed in a containerized environment using Docker.
- Docker Compose reused with requested changes:
  - code is mounted through a volume
  - different ports and container names are used

## 2. Repository Used

GitHub repository for Part II:
- https://github.com/Mubashir3344/assignment-2.git

## 3. Jenkins Setup on EC2 (Micro Steps)

1. SSH into EC2 instance.
2. Install Docker Engine and Docker Compose plugin.
3. Add ubuntu user to docker group.
4. Start Jenkins via Docker Compose (`docker-compose.jenkins.yml`).
5. Open Jenkins at `http://<EC2_PUBLIC_IP>:8081`.
6. Unlock Jenkins using initial admin password.
7. Install required plugins:
- Git plugin
- Pipeline plugin
- Docker Pipeline plugin
8. Create admin user and finish setup.

## 4. GitHub Integration (Micro Steps)

1. Push project code to `assignment-2` repository.
2. In Jenkins, create a Pipeline job.
3. Configure SCM to Git and set repository URL.
4. Set script path to `Jenkinsfile`.
5. In GitHub repository settings, add webhook:
- Payload URL: `http://<EC2_PUBLIC_IP>:8081/github-webhook/`
- Content type: `application/json`
- Events: push events
6. Enable build trigger in Jenkins job (`GitHub hook trigger for GITScm polling`).

## 5. Pipeline Design

Pipeline stages implemented in `Jenkinsfile`:
1. Checkout source code from GitHub.
2. Containerized build using `docker-compose.jenkins.yml` with code volume mounted.
3. Build Docker images for API and web.
4. Tag images with build number and `latest`.
5. Cleanup compose services and temporary docker artifacts.

## 6. Required File Artifacts

## 6.1 Jenkinsfile

```groovy
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
```

## 6.2 docker-compose.jenkins.yml

```yaml
services:
  jenkins_ci:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins-ci-server
    user: root
    restart: unless-stopped
    ports:
      - "8081:8080"
      - "50001:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - ./:/workspace
    working_dir: /workspace

  web_builder:
    image: node:20-alpine
    container_name: singitronic-web-build
    working_dir: /workspace
    volumes:
      - ./:/workspace
    command: sh -lc "npm ci && npm run build"

  api_builder:
    image: node:20-alpine
    container_name: singitronic-api-build
    working_dir: /workspace
    volumes:
      - ./:/workspace
    command: sh -lc "cd server && npm ci && npx prisma generate"

  db_ci:
    image: mysql:8.4
    container_name: singitronic-db-ci
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root_local_2026
      MYSQL_DATABASE: singitronic_nextjs_ci
      MYSQL_USER: singitronic_user
      MYSQL_PASSWORD: singitronic_local_2026
    ports:
      - "3307:3306"
    volumes:
      - mysql_ci_data:/var/lib/mysql

volumes:
  jenkins_home:
  mysql_ci_data:
```

## 7. Screenshots to Include in Submission

1. Jenkins running on EC2 (`http://<IP>:8081`).
2. Installed Jenkins plugins page (Git, Pipeline, Docker Pipeline).
3. Pipeline job configuration with GitHub repo URL.
4. GitHub webhook configuration page.
5. Successful pipeline run console output.
6. Docker images built/tagged after pipeline run.
7. Running Jenkins compose services (`docker compose -f docker-compose.jenkins.yml ps`).

## 8. Conclusion

Part II requirements were completed by integrating Jenkins, GitHub webhook, and Docker-based build automation on EC2. The build pipeline runs in a containerized environment and reuses Docker Compose with code volume mounting, different ports, and different container names.

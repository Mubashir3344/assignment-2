# Part II Report: Containerized Automation Pipeline with Jenkins (AWS EC2)

## 1. Project Objective

For Part II, the objective was to automate the build and deployment process of the same application used in Part I by using Jenkins on AWS EC2, integrated with GitHub webhook triggers.

Completed objectives:
- Jenkins installed and configured on EC2.
- GitHub repository integrated with Jenkins pipeline job.
- Push events trigger pipeline automatically (webhook + Poll SCM fallback).
- Build phase runs in containerized environment using Docker.
- Reused compose setup with required assignment constraints:
  - code mounted via volumes
  - different ports and container names for Part II

---

## 2. Repository and Infrastructure

- GitHub repo: `https://github.com/Mubashir3344/assignment-2.git`
- EC2 public IP used: `3.101.109.184`
- Jenkins UI: `http://3.101.109.184:8081`
- Part I runtime: `3000` (web), `3001` (api)
- Part II runtime: `4000` (web), `4001` (api), `3308` (db)

---

## 3. Final Part II Architecture

Part II uses two compose files:

1. `docker-compose.jenkins.yml`
- Runs Jenkins and build helper services.
- Mounts host project path into containers as `/workspace`.
- Uses Docker socket mount for Jenkins pipeline Docker commands.

2. `docker-compose-part2.yml`
- Runs deployment stack for Part II only.
- Services:
  - `singitronic-db-part2`
  - `singitronic-api-part2`
  - `singitronic-web-part2`
- Uses code volume mounts and different ports from Part I.

This satisfies assignment requirement for reusing compose with modified ports/container names and code-volume workflow.

---

## 4. Jenkins Pipeline Flow (Final)

Pipeline stages in final `Jenkinsfile`:

1. Checkout
- Pull latest code from GitHub `main`.

2. Prepare Docker CLI
- Ensures `docker` and `docker-compose` exist in Jenkins runtime.

3. Containerized Build (Code Volume)
- Uses `web_builder` container to run:
  - dependency install
  - `next build`
- Uses `api_builder` container to run:
  - dependency install
  - `prisma generate`

4. Deploy Part II (Ports 4000/4001)
- Stops previous Part II stack.
- Starts new Part II stack.
- Waits briefly and verifies API/Web containers are running.
- Prints final deployment URLs.

5. Post cleanup
- Stops/removes temporary builder/db_ci services only.
- Does not stop Jenkins itself.

---

## 5. Trigger Strategy

Auto-trigger configuration:
- `githubPush()` in Jenkinsfile
- `pollSCM('H/2 * * * *')` fallback in Jenkinsfile
- GitHub webhook configured to:
  - `http://3.101.109.184:8081/github-webhook/`
  - push events only

This ensures pipeline starts automatically on push and still works if webhook delivery is delayed.

---

## 6. Main Issues Faced and Final Fixes

1. `docker: not found` in Jenkins pipeline
- Cause: Jenkins runtime lacked Docker CLI.
- Fix: Added `Prepare Docker CLI` stage to install `docker.io` and `docker-compose`.

2. Webhook delivered but build status inconsistent
- Cause: readiness check used endpoints not always reachable from Jenkins container context.
- Fix: simplified deployment verification to container running-state checks.

3. `No space left on device (ENOSPC)`
- Cause: repeated runtime installs and volume churn.
- Fix: cleaned Docker resources and removed unnecessary repeated runtime install behavior.

4. API startup `Merchant table does not exist`
- Cause: no migration files in project, so `migrate deploy` had nothing to apply.
- Fix: switched startup schema step to `prisma db push` for Part II runtime.

5. Web startup `Could not find production build in .next`
- Cause: startup/build ordering and stale container state in earlier revisions.
- Fix: ensured build step happens in CI flow and web container starts correctly on Part II stack.

---

## 7. Final EC2 Operational Commands

## 7.1 Keep Part II down initially (as required)

```bash
cd ~/assignment-2
docker compose -f docker-compose-part2.yml down
```

## 7.2 Jenkins remains up

```bash
docker compose -f docker-compose.jenkins.yml up -d jenkins_ci
docker compose -f docker-compose.jenkins.yml ps
```

## 7.3 Verify trigger (after pushing a commit)

```bash
docker logs --tail=200 jenkins-ci-server
```

## 7.4 Check Part II after trigger

```bash
docker compose -f docker-compose-part2.yml ps
curl http://localhost:4001/health
curl -I http://localhost:4000
```

---

## 8. Required Artifact Files (Part II)

- `Jenkinsfile`
- `docker-compose.jenkins.yml`
- `docker-compose-part2.yml`

These three files represent the final Part II implementation.

---

## 9. Screenshots Checklist for Submission

1. Jenkins dashboard on EC2 (`:8081`).
2. Jenkins job configuration (SCM + triggers).
3. GitHub webhook configuration and successful delivery.
4. Pipeline console showing full successful run.
5. `docker compose -f docker-compose-part2.yml ps` showing Part II services.
6. Browser showing app on `http://3.101.109.184:4000`.
7. API health output on port `4001`.
8. Proof that Part II is initially down and then up after push.

---

## 10. Conclusion

Part II is fully implemented with Jenkins-based CI/CD automation for the same application used in Part I. The final setup supports automatic push-triggered build/deploy behavior, uses containerized build steps, and deploys Part II on separate ports and container names exactly as required by the assignment.

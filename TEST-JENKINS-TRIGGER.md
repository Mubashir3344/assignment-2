# Jenkins Trigger Test

This file exists only to test GitHub webhook-triggered Jenkins builds for Part II.

## Expected behavior

- A push to `main` triggers Jenkins automatically.
- Jenkins pipeline deploys Part II services.
- Part II web becomes available on port `4000`.
- Part II API becomes available on port `4001`.

## Test note

If this commit appears in Jenkins build history, webhook trigger is working.

## Trigger check update

Second webhook test commit from local machine to verify automatic Jenkins trigger on push.

## Trigger check update 2

Third webhook test commit to confirm pipeline auto-trigger behavior after Jenkinsfile updates.

## Trigger check update 3

Final markdown-only change to verify Jenkins webhook and pipeline trigger after bringing Part II down.

## Trigger check update 4

Post-fix trigger commit to validate Jenkins can run docker compose commands.

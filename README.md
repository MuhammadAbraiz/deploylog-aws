# deploylog-aws

A tiny API that records deployments, and the pipeline that deploys it.
Every successful deploy writes its own record to the API.

- `POST /deployments` records a deployment (IAM-signed requests only)
- `GET /deployments?service=deploylog` lists the latest 20

Built on Lambda (Python), API Gateway HTTP API and DynamoDB, deployed with
Terraform from GitHub Actions. No AWS access keys are stored in GitHub: the
workflow signs in with OIDC and gets credentials that expire in an hour.

## Layout

| Path | What it is |
| --- | --- |
| `app/` | Lambda handler |
| `infra/` | App infrastructure, applied by CI |
| `bootstrap/` | One-time setup: OIDC deploy role, state bucket, lock table |
| `.github/workflows/` | Deploy pipeline |

## Setup

1. Apply the bootstrap once with admin credentials:

   ```sh
   cd bootstrap
   terraform init
   terraform apply
   ```

   Set `create_oidc_provider = true` if your account has no GitHub OIDC provider yet.

2. In the GitHub repo settings, add:
   - Secret `AWS_ROLE_ARN` = `deploy_role_arn` output
   - Secret `TF_STATE_BUCKET` = `state_bucket` output
   - Variable `TF_LOCK_TABLE` = `lock_table` output

3. Push to `main`. The workflow deploys and records itself.

## Articles

1. GitHub Actions to AWS with OIDC (`step-01`)

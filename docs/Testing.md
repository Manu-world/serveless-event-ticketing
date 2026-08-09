# How to test the BadexTechEvents stack (dev first, then promote)

Use this ladder. Fail cheaply and early before touching production.

## 1. Static checks (no AWS)

```bash
make tf-fmt
make lint
make ENV=dev tf-validate
make ENV=prod tf-validate
```

## 2. Unit tests (moto, no AWS)

```bash
make test-unit
# or: make test
```

All handler logic is covered with in-memory DynamoDB/SNS/SSM mocks.

## 3. Plan review (dev)

```bash
# Copy and fill secrets once
cp infrastructure/environments/dev/terraform.tfvars.example \
   infrastructure/environments/dev/terraform.tfvars

cd infrastructure/environments/dev
terraform init
terraform plan
```

Expect a greenfield create of `event-ticketing-dev-*` resources. Confirm nothing touches `event-ticketing-prod-*`.

## 4. Apply the slim dev environment

```bash
make ENV=dev tf-apply
```

Capture outputs:

```bash
terraform -chdir=infrastructure/environments/dev output
```

You need:

- `api_endpoint`
- `cloudfront_distribution_id`
- `frontend_bucket`
- `github_actions_deploy_role_arn`
- `github_actions_terraform_role_arn`

Wire those into the GitHub Environment named `dev` (same secret names as prod).

## 5. Integration smoke against dev

```bash
export API_BASE_URL="$(terraform -chdir=infrastructure/environments/dev output -raw api_endpoint)"
export ADMIN_API_KEY="$(grep admin_api_key infrastructure/environments/dev/terraform.tfvars | cut -d'"' -f2)"
make test-integration
```

This covers:

1. Admin create event (valid key)
2. Public register
3. Lookup registrations
4. Cancel registration
5. Admin delete event
6. Negative case: missing `x-api-key` is rejected

## 6. Observability spot-check

```bash
aws logs tail /aws/lambda/event-ticketing-dev-register --since 10m --follow
aws cloudwatch describe-alarms --alarm-name-prefix event-ticketing-dev --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}'
```

Confirm X-Ray traces appear for a few invocations in the console if needed.

## 7. Frontend against dev

```bash
API_URL="$API_BASE_URL"
sed "s|__API_BASE_URL__|$API_URL|g" frontend/index.html > /tmp/index.dev.html
# Or sync the whole frontend after injecting:
sed -i.bak "s|__API_BASE_URL__|$API_URL|g" frontend/index.html
make ENV=dev deploy-frontend CLOUDFRONT_DIST_ID="$(terraform -chdir=infrastructure/environments/dev output -raw cloudfront_distribution_id)"
# restore local placeholder if you edited in place
mv frontend/index.html.bak frontend/index.html 2>/dev/null || true
```

Open `https://$(terraform -chdir=infrastructure/environments/dev output -raw cloudfront_domain_name)`.

## 8. Promote or tear down

Promote only after steps 1–7 pass:

1. Merge `dev` → `main` (or open a PR)
2. Terraform workflow applies prod (protected environment)
3. Deploy workflow publishes Lambda + frontend to prod

Or destroy the disposable stack:

```bash
make ENV=dev tf-apply  # if you need a clean re-apply later
cd infrastructure/environments/dev && terraform destroy
```

## Environment differences (why slim-dev exists)

| Knob | Dev | Prod |
| --- | --- | --- |
| Log retention | 7 days | 30 days |
| DynamoDB PITR | off | on |
| Detailed alarms (duration/DDB) | off | on |
| Budget | $1 | $5 |
| S3 force destroy | true | false |
| DynamoDB deletion protection | false | true |
| API throttle | lower | higher |

Shared (account-level) resources live in `infrastructure/bootstrap/` (state bucket + GitHub OIDC provider) and must never be duplicated per environment.

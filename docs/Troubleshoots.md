# Deployment Troubleshooting & Lessons Learned

While deploying the BadexTechEvents ticketing system to production, I ran into a few interesting edge cases across our testing, CI/CD, and AWS infrastructure layers.

I'm documenting the issues I faced, my thought process while troubleshooting them, how I eventually fixed them, and what we can take away for future serverless projects.

---

## 1. Pytest Crashing Before Tests Even Ran

**The Problem:**
When I ran `make test` locally, the test suite crashed immediately during the "collection" phase with a bunch of errors saying `ValueError: Required parameter name not set`. It was failing on `src/create_event.py` and other Lambda handlers.

**My Thinking Process:**
The stack trace pointed deep into `boto3` when trying to initialize a DynamoDB table. I looked at the top of my Lambda handlers and saw this:
```python
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))
```
This code runs at **module-level scope**. When `pytest` runs, it scans the test files, which import the Lambda handlers. Because python evaluates module-level code immediately upon import, `boto3` was trying to connect to a DynamoDB table before any of my Pytest fixtures (like `mock_env`) had a chance to set the `TABLE_NAME` environment variable!

**The Resolution:**
I opened `tests/conftest.py` and added a block at the *very top* of the file—before any handlers or even `boto3` are imported—that sets the required environment variables:
```python
import os
os.environ.setdefault('TABLE_NAME', 'test-table')
# ... other vars ...
import boto3  # noqa: E402
```
*(I had to add `noqa: E402` to tell the linter to ignore that the imports weren't strictly at the top of the file, because the env vars absolutely had to come first).*

**The Takeaway:**
When building serverless functions, be very careful with initializing AWS SDK clients (like `boto3`) at the module level if they rely on environment variables. Either initialize them inside the handler function itself, or ensure your test suite bootstraps the environment before importing anything.

---

## 2. The GitHub Actions Chicken-and-Egg Problem

**The Problem:**
Our GitHub Actions pipeline (`deploy-backend`) was failing on the "Configure AWS Credentials" step with the error: `Could not load credentials from any providers`.

**My Thinking Process:**
Our pipeline uses `aws-actions/configure-aws-credentials` and authenticates securely to AWS via OIDC using a GitHub Secret: `role-to-assume: ${{ secrets.AWS_OIDC_ROLE_ARN }}`.
If it's failing to find credentials, that means the secret is empty or missing. But wait... the IAM Role that GitHub is supposed to assume is defined in our *new* Terraform code (`iam.tf`). If the CI/CD pipeline is responsible for applying our Terraform, but it needs the Terraform-created IAM Role to authenticate in the first place... we have a chicken-and-egg problem!

**The Resolution:**
I bypassed the CI/CD pipeline temporarily. I used my local AWS administrator credentials to run `terraform apply` directly from my machine. This "bootstrapped" the environment, creating the OIDC IAM Role. Once it was created, I grabbed the `github_actions_role_arn` from the Terraform outputs and saved it into the GitHub Repository Secrets. From then on, the pipeline had the credentials it needed to run automatically.

**The Takeaway:**
When setting up OIDC-based CI/CD pipelines (which is a great security practice since you don't have long-lived access keys), you must always manually provision the IAM trust policies *first* before the automated pipeline can take over.

---

## 3. AWS Lambda Concurrency Quotas

**The Problem:**
While running `terraform apply` to deploy our backend, Terraform threw a nasty error:
`InvalidParameterValueException: Specified ReservedConcurrentExecutions for function decreases account's UnreservedConcurrentExecution below its minimum value of [10].`

**My Thinking Process:**
I checked `terraform/lambda.tf`. For our 8 Lambda functions, I had hardcoded a block that said:
```hcl
reserved_concurrent_executions = 10
```
Because I applied this to all 8 functions in a loop, Terraform tried to reserve 80 concurrent executions total. By default, standard AWS accounts (especially newer ones) only have an account-wide unreserved concurrency limit of 10 to 50. By asking for 80, I was starving the account's unreserved pool, and AWS blocked the deployment.

**The Resolution:**
I completely removed the `reserved_concurrent_executions = 10` line from the Terraform configuration. By removing it, the Lambda functions simply share the account's unreserved concurrency pool, which is perfectly fine for a new project. I committed this fix to the `main` branch.

**The Takeaway:**
Never hardcode high reserved concurrency limits on your Lambda functions unless you actually need guaranteed scaling for a specific function *and* you have explicitly requested a quota increase for your AWS account. It's safer to leave it unset during initial development.

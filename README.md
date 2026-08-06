# Serverless Event Registration & Ticketing API

An enterprise-grade, serverless REST API built on AWS to replace manual Microsoft Forms and Excel ticketing workflows. This system provides highly scalable, automated event registration with built-in CI/CD, Infrastructure as Code (IaC), and observability.

## 🚀 Architecture Overview

This project implements a fully serverless, event-driven architecture using modern cloud best practices.

*   **Compute:** AWS Lambda (Python 3.10)
*   **API Layer:** Amazon API Gateway (HTTP API v2 for lower latency and native CORS)
*   **Database:** Amazon DynamoDB (Single-Table Design pattern)
*   **Observability:** Amazon CloudWatch (Logs, Custom Metrics, and Alarms)
*   **Notifications:** Amazon SNS (Automated email confirmations)
*   **Infrastructure as Code:** HashiCorp Terraform
*   **CI/CD:** GitHub Actions with OpenID Connect (OIDC) authentication

## 🔒 Security & Optimization Highlights
*   **IAM Least Privilege:** All Lambda execution roles are strictly scoped to the exact ARNs of the resources they interact with.
*   **Keyless CI/CD:** GitHub Actions authenticates to AWS dynamically via OIDC. No static, long-lived AWS Access Keys are stored in GitHub Secrets.
*   **API Throttling:** API Gateway is configured with strict burst and rate limits to mitigate DDoS risks and protect AWS Free Tier limits.
*   **Cost Management:** AWS Budgets is hardcoded into the infrastructure deployment to trigger alerts if spending exceeds $1.00.

## 📡 API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/register` | Registers a user for an event and triggers an SNS email confirmation. |
| `GET` | `/events` | Retrieves all available events. |
| `GET` | `/registrations/{email}` | Fetches all active registrations linked to a specific email via a DynamoDB GSI. |
| `DELETE` | `/registration/{id}` | Cancels a specific ticket/registration. |

## 🛠️ Deployment Instructions

### 1. Infrastructure Provisioning (Terraform)
Navigate to the `terraform/` directory, update the `variables.tf` with your specifics, and deploy:
\`\`\`bash
terraform init
terraform plan
terraform apply -auto-approve
\`\`\`
*Note the `api_endpoint` URL generated in the Terraform outputs.*

### 2. CI/CD Application Deployment
Pushing to the `main` branch triggers the GitHub Actions pipeline (`deploy.yml`). The workflow will automatically install dependencies, run `pytest` unit validations, zip the Python source code, and deploy the updates directly to the AWS Lambda compute layer.
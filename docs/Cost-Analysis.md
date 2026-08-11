# Cost Analysis — BadexTechEvents

This note explains **why** each major AWS choice in this project was made with cost in mind, how the **dev** and **prod** environments differ on purpose, and what a realistic monthly bill looks like at low traffic.

---

## 1. Design goal

Build a production-shaped event registration system that:

1. Stays inside a **hard monthly ceiling** (`$1` for dev, `$5` for prod) with budget alerts at **80%**.
2. Uses **pay-per-use** services only — no always-on compute or provisioned databases.
3. Keeps **dev cheaper than prod** without maintaining a second codebase.

The stack is entirely serverless: S3 + CloudFront, API Gateway HTTP API, Lambda, DynamoDB on-demand, SNS, SSM, CloudWatch.

---

## 2. Decision log (what I chose and why)

| Decision | Alternative I rejected | Cost / ops reason |
| --- | --- | --- |
| **Lambda** (128 MB, 15s, python3.12) | EC2 / ECS / Elastic Beanstalk | Idle cost is ~$0. No fleet to patch. 128 MB is the cheapest memory tier that still fits the handlers. |
| **No reserved concurrency** | Pinning concurrency per function | Reserved concurrency burns account quota and can create idle reserved capacity you still “own”. We hit quota pain once; removing it simplified billing and ops. See [Troubleshoots.md](./Troubleshoots.md). |
| **DynamoDB PAY_PER_REQUEST** | Provisioned RCUs/WCUs (+ autoscaling) | Traffic is bursty and low. On-demand avoids paying for capacity that sits unused overnight. |
| **Single-table design + GSIs** | Multiple tables / `Scan` | `Query` on `SKIndex`, `UserEmailIndex`, and `RegistrationIdIndex` keeps read cost predictable. Scans scale with table size and waste RCU. |
| **API Gateway HTTP API (v2)** | REST API (v1) | HTTP APIs are cheaper per million requests and enough for our auth model (Lambda authorizer + JWT-less API key). |
| **S3 + CloudFront (OAC)** | Public S3 website hosting / ALB | Static assets cached at the edge; bucket stays private. No ALB hourly charge. |
| **Default CloudFront certificate** | ACM + custom domain | Fine for a portfolio / lab deploy. Custom domains add ACM + Route 53 cost when we need them. |
| **SSM SecureString for secrets** | Plaintext Lambda env vars for passwords | Cost is negligible; avoids leaking SMTP / admin keys in console screenshots and deploy logs. |
| **Explicit CloudWatch retention** | Leave “Never expire” | Log storage is a silent bill. Dev keeps **7 days**; prod keeps **30 days**. |
| **SMTP only in prod** (`email_provider`) | Always-on SES sandbox / SMTP in both envs | Dev sets `email_provider = none` so smoke tests never open real SMTP sessions or send junk mail. |
| **AWS Budgets per environment** | Checking Cost Explorer manually | Automated email when spend crosses **80%** of the env ceiling. |

---

## 3. Environment differentiation (same modules, different knobs)

Both environments call the same Terraform modules. Cost and durability knobs are **variable defaults** in each env’s `variables.tf` — not scattered hardcodes.

| Knob | Dev (slim) | Prod (hardened) | Why it differs |
| --- | --- | --- | --- |
| `budget_limit_usd` | **$1.00** | **$5.00** | Dev is a sandbox; prod needs headroom for real email + longer logs + PITR. |
| `log_retention_days` | **7** | **30** | Debugging window vs storage cost. |
| `enable_pitr` | **false** | **true** | PITR is continuous backup cost; worth it only where data matters. |
| `enable_detailed_alarms` | **false** | **true** | Duration + DynamoDB throttle alarms are useful in prod; each alarm is a small monthly charge. Error-rate + API 5xx stay on in both. |
| `throttling_rate_limit` / `burst` | **25 / 50** | **50 / 100** | Caps runaway clients (and runaway bills) tighter in dev. |
| `email_provider` | **none** | **smtp** | Zero outbound mail cost / noise in dev. |
| `s3_force_destroy` | **true** | **false** | Cheap to tear down a lab bucket; protect prod objects. |
| `dynamodb_deletion_protection` | **false** | **true** | Same idea for the table. |

Source of truth: `infrastructure/environments/{dev,prod}/variables.tf`, also summarized in [Testing.md](./Testing.md).

---

## 4. Rough monthly cost model (low traffic)

Assumptions for a **portfolio / lab** load (orders of magnitude, not a quote):

- ~50k API requests / month across all routes
- ~50k Lambda invocations, ~100 ms average, 128 MB
- DynamoDB: tens of thousands of on-demand reads/writes
- CloudFront: a few GB of static asset traffic
- CloudWatch: retained logs as configured above
- Prod only: occasional SMTP (Gmail app password — no AWS SES charge)

| Service | How it bills | Expected at this load |
| --- | --- | --- |
| Lambda | per GB-second + requests | Cents (well inside Free Tier for new accounts) |
| API Gateway HTTP API | per million requests | Cents |
| DynamoDB on-demand | per million r/w units | Cents–low dollars |
| S3 | storage + requests | Near-zero for a static UI |
| CloudFront | data transfer + requests | Cents for a small site |
| CloudWatch Logs | ingestion + storage | Main variable — limited by retention |
| CloudWatch Alarms | per alarm / month | Low dollars in prod (more alarms) |
| X-Ray | traces sampled | Cents at this volume |
| SNS | email notifications | Negligible |
| SSM | standard parameters | Negligible |
| AWS Budgets | first few budgets | Often free / negligible |
| **Guardrail** | — | **Dev ≤ $1 · Prod ≤ $5** (alert at 80%) |

If Cost Explorer shows a spike, the usual suspects are **CloudWatch log retention**, **unexpected traffic past the throttle**, or **leaving detailed alarms + PITR on in a forgotten stack**. That is exactly why the slim-dev defaults exist.

---

## 5. What the Free Tier still covers (when eligible)

On a new AWS account Free Tier, most of this workload sits inside:

- Lambda request and compute allowances
- DynamoDB on-demand Free Tier
- S3 and CloudFront introductory allowances
- API Gateway Free Tier (HTTP APIs have their own request allowance)

The budgets still matter: Free Tier does **not** cover everything (alarms, some log storage, data transfer overages), and this project is meant to stay cheap **after** Free Tier expires too.

---

## 6. What I would change if traffic grew

Cost optimization is not “always pick the cheapest knob.” If the product moved past lab scale I would revisit, in order:

1. **CloudFront PriceClass** — pin to `PriceClass_100` if users are mostly in one region.
2. **Lambda memory / architecture** — profile with X-Ray; sometimes more memory *lowers* GB-seconds. Consider `arm64` (Graviton) for a ~20% compute discount.
3. **DynamoDB** — if traffic becomes steady and high, compare provisioned + autoscaling vs on-demand with Cost Explorer.
4. **SES** instead of SMTP — better deliverability and clearer AWS billing than a Gmail relay once email volume is real.
5. **Log sampling / EMF metrics** — keep alarms, reduce raw log volume.
6. **Custom domain + caching headers** — fewer origin hits to S3 for static assets.

Until then, the current shape matches the goal: **demonstrate a real AWS architecture without an open-ended bill**.

---

## 7. How to verify spend yourself

```bash
# Budgets (names)
#   event-ticketing-dev-budget   → $1
#   event-ticketing-prod-budget  → $5

aws budgets describe-budget \
  --account-id "$(aws sts get-caller-identity --query Account --output text)" \
  --budget-name event-ticketing-prod-budget
```

Also check **AWS Cost Explorer → Group by: Service** filtered to the last 30 days, and the email that fires when actual spend crosses 80% of either budget.

---

## 8. Summary

| Principle | How it shows up in this repo |
| --- | --- |
| No idle compute | Lambda + HTTP API + on-demand DynamoDB |
| Pay for durability only where needed | PITR / deletion protection / longer logs in **prod only** |
| Cap surprise bills | Per-env AWS Budgets + API throttling |
| Same code, cheaper sandbox | Slim defaults in `environments/dev` |
| Prefer Query over Scan | Single-table GSIs |
| Don’t reserve what you don’t use | No Lambda reserved concurrency |

The architecture is intentionally “boring serverless” — that boringness is the cost strategy.

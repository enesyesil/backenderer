


# Backenderer
![Project Status: Planning](https://img.shields.io/badge/status-planning-yellow)

**Backenderer** is a lightweight, secure, and decentralized backend deploy kit for students and hobbyists.  
Deploy your backend app to your own AWS account in **seconds** — no servers to manage, no SSH needed.

---

##  Features
- **Two Deployment Modes**
  1. **Source Build** → Put your code + `Dockerfile` in `/app` (must listen on port `8080` inside container).
  2. **Image Deploy** → Put your Docker image URI in `/image/ref.txt` (e.g., `ghcr.io/username/project:tag`).
- **Secure by Default**
  - No SSH, SSM-only
  - Hardened Docker & Nginx configs
  - TLS 1.2/1.3 + HSTS + rate limits
- **AWS Native**
  - OIDC-based deploy from GitHub Actions
  - Push images to Amazon ECR
  - Run on Amazon Linux EC2 (t3.micro by default)

---

## Repo Structure

- `/app` — Option A: Put your source code + Dockerfile here  
- `/image/ref.txt` — Option B: Put your existing Docker image URI here  
- `/aws/role.yaml` — AWS OIDC deploy role (CloudFormation)  
- `/aws/instance.cfn.yaml` — EC2 + SG + IAM + optional Route53 stack  
- `/bootstrap/` — EC2 user-data templates  
- `/scripts/` — register/unregister app scripts (run via SSM)  
- `/.github/workflows/deploy_ec2.yml` — GitHub Actions pipeline  



---

##  Quick Start

### 1. Fork this repo

### 2. Choose a deployment mode

#### Option A – Build from Source
1. Add your app code and `Dockerfile` under `/app/`.
2. Ensure your app listens on **port 8080** inside the container.

#### Option B – Deploy Existing Image
1. Put your image URI in `/image/ref.txt`:



---

### 3. Set up AWS OIDC Role

1. In AWS Console → **CloudFormation** → create stack with `/aws/role.yaml`.
2. Copy the output **DeployRoleArn**.

---

### 4. Add GitHub Actions Secrets

In your fork → **Settings → Secrets and Variables → Actions**:
- `AWS_ROLE_ARN` → The DeployRoleArn from step 3
- `AWS_REGION` → e.g., `us-east-1`
- *(Optional)* `DOMAIN_NAME` and `HOSTED_ZONE_ID` for HTTPS on a custom domain.

---

### 5. Deploy 

1. Go to your fork → **Actions** → **Deploy to AWS (EC2)** → **Run workflow**.
2. Wait for completion.
3. Get your app URL from workflow output

---

##  Security Defaults
- No SSH (SSM only)
- IMDSv2 enforced
- Least privilege IAM
- Hardened Nginx (TLS 1.2/1.3, HSTS, CSP)
- Docker: non-root, read-only FS, dropped capabilities, resource limits

---
## AWS Cost Estimate

Backenderer is designed to be **student & hobbyist friendly** — you can usually run it for free (first year) or very cheap after that.

### Free Tier (First 12 months)
- **EC2 t3.micro** (750 hrs/month) → FREE  
- **EBS Storage (8–10 GB)** → FREE  
- **ECR (500 MB storage)** → FREE  
- **SSM / CloudFormation** → FREE  
- **Data transfer** → 1 GB/month outbound FREE  

> If you’re in your AWS Free Tier period, you can run Backenderer 24/7 at **$0 cost**.

---

### After Free Tier
Typical monthly costs (for one always-on instance):

| Service          | Cost Estimate |
|------------------|---------------|
| EC2 t3.micro     | $7–8 / month |
| EBS (10 GB)      | ~$1 / month |
| ECR (small usage)| $0–1 / month |
| Data transfer    | ~$1–2 / month (light traffic) |
| **Total**        | **$10–12 / month** |

---

### Optional Domain (Route53 + TLS)
- Domain name: ~$12/year  
- Hosted zone: $0.50/month  
- DNS queries: negligible  
- Certificates: FREE (Let’s Encrypt via certbot)  

> With a domain: expect **+$1/month** plus domain registration cost.

---

**Summary:**  
- Free in Year 1 (if you use AWS Free Tier).  
- After Free Tier: **~$10–15/month** steady state.  

---



##  Extending
Future versions will add:
- GCP & Azure support
- Custom container ports
- Automatic CloudWatch logging & alarms
- Per-app Basic Auth

---

**Backenderer** – Deploy your backend, anywhere, in seconds.

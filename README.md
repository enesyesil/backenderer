# Backenderer 🚀

**Backenderer** is a lightweight, plug-and-play deployment system for backend apps.  
Fork this repo, add your app (or reference an existing Docker image), connect your AWS account, and deploy in minutes.

##  Features

- **Stateless template** → no state committed; safe to fork and reuse.  
- **Terraform-based infra** → EC2 + Docker + Nginx reverse proxy.  
- **Secure by default** → OIDC role for GitHub Actions, no SSH access (managed via SSM).  
- **Config-driven deploys** → describe apps in YAML (`examples/*.yaml`).  
- **Multi-app hosting** → register/unregister apps dynamically, Nginx handles routing.  
- **TLS/DNS options** → `none`, `letsencrypt`, or `alb_acm`.  
- **Extendable** → future support for other clouds/providers.


---


##  Repo Structure

- `/app/` — Option A: put your app source + Dockerfile here  
- `/image/ref.txt` — Option B: reference an existing Docker image  
- `/examples/` — Sample deploy configs (single-app, multi-app)  
- `/infra/terraform/` — Infra code (dev & prod envs)  
- `/infra/docs/` — Extra docs (state, config schema, etc.)  
- `/scripts/` — register/unregister app scripts (run via SSM)  
- `/.github/workflows/` — CI workflows (infra, deploy, remove)


---

## 🚀 Quickstart

### 1. Bootstrap Infra
Run Terraform to set up IAM role, EC2 instance, and (optionally) ECR.

```bash
cd infra/terraform/envs/dev
cp dev.tfvars.example dev.tfvars
# edit dev.tfvars with your values (AMI, instance_type, etc.)
terraform init
terraform apply -var-file=dev.tfvars
```
Terraform will output:

- `role_arn` → for GitHub OIDC
- `instance_id`, `instance_public_ip`
- `ecr_repo_url` (if `create_ecr = true`)
- `alb_dns_name` (if using ALB/TLS)

---

### 2. Configure GitHub Actions

In your fork, go to **Settings → Secrets and variables → Actions** and add:

- `AWS_ROLE_ARN` → value = `role_arn` from Terraform
- `AWS_REGION` → your region (e.g., `us-east-1`)

**Optional (for remote state):**
- `TFSTATE_BUCKET`
- `TF_LOCK_TABLE`

### 3. Deploy Your App

Commit a config file (example below) and trigger the **Deploy App** workflow:

```yaml
# examples/single-app.yaml
env: dev
apps:
  - name: myapp
    image: ghcr.io/<user>/<repo>:latest
    host: myapp.localtest.me
    port: 8080
```

Workflow will:

- Build or pull your Docker image  
- Push to ECR or GHCR  
- Register the app via SSM on your EC2 host  
- Update Nginx and reload  

Check health:

```bash
curl http://<server-ip>/backenderer/health
```
---
##  Environments

- **`dev/`** → defaults for testing (uses local state).  
- **`prod/`** → production defaults (can use remote state with S3 + DynamoDB).  

See [`infra/docs/state.md`](infra/docs/state.md) for details on enabling remote state.

---

## Security

- No SSH access; all operations use AWS Systems Manager (SSM).
- GitHub Actions authenticates via OIDC to assume an IAM role (no long-lived keys).
- TLS options: `none`, `letsencrypt`, or `alb_acm` (configure in Terraform).
- Principle of least privilege: limit the OIDC role to required services (EC2, SSM, ECR, S3/DynamoDB if using remote state).

---

## Workflows

- **Infra** → plans and applies Terraform (`infra.yml`).  
- **Deploy App** → builds/pushes app image, registers via SSM (`deploy.yml`).  
- **Remove Stack** → terminates instance or destroys stack (`remove.yml`).  

---

## Docs

- [`CONFIG.md`](infra/docs/CONFIG.md) → app configuration schema  
- [`state.md`](infra/docs/state.md) → local vs remote state guide  
- [`quickstart.md`](infra/docs/quickstart.md) → step-by-step walkthrough  
- [`cost.md`](infra/docs/cost.md) → estimated AWS costs and budgeting notes  


---


## Roadmap

- Multi-cloud provider support  
- Auto-scaling groups / spot instances  
- Metrics & monitoring integration  
- Terraform modules for VPC, RDS, etc.  

---

## Contributing

Fork this repo, use it for your own apps, and feel free to open pull requests with improvements.  
Issues and feature requests are welcome to help make Backenderer more useful for everyone.  

## License

This project is licensed under the MIT License.  
See the [LICENSE](LICENSE) file for details.  



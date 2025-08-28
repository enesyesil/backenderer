# Backenderer QuickStart

Deploy your first app in **3 steps** 🚀

---

## 1. Bootstrap Infra
Run Terraform to set up the IAM role, EC2 instance, optional ECR repo, and TLS config.

```bash
cd infra/terraform/envs/dev
terraform init
terraform apply -var-file=dev.tfvars
```
Outputs will include:

- role_arn → for GitHub Actions OIDC

- instance_id + instance_public_ip

- ecr_repo_url (if create_ecr = true)

- tls_mode / alb_dns_name

## 2. Configure GitHub Actions

In your repo settings → Actions → Secrets & Variables → Add:

AWS_ROLE_TO_ASSUME → value = role_arn from Terraform

AWS_REGION → same region you deployed to


## 3. Deploy Your App

Commit a config file (e.g. examples/single-app.yaml) and trigger the Deploy App workflow:

env: dev

config_file: examples/single-app.yaml

GitHub Actions will:

Build or use your Docker image

Push to ECR or GHCR

Run register.sh on the EC2 instance via SSM

Reload Nginx

Verify health at /backenderer/health

## `infra/docs/config.md`

```md
# Backenderer Config Reference

One YAML file drives all deploys.

---

## Top-level keys
- `multi_app`: false = single app, true = multiple apps
- `mode`: source | image
- `registry`: ecr | ghcr
- `image_prefix`: prefix for GHCR image tags (when mode=source)
- `tls_email`: email used for Let's Encrypt certificates

---

## Single-App Example
```yaml
multi_app: false
mode: source
registry: ecr
name: hello
server_name: hello.example.com
container_port: 8080
```

## Multi-App Example
```yaml
multi_app: true
mode: image
registry: ghcr
image_prefix: svc-
apps:
  - name: api
    server_name: api.example.com
    container_port: 8000
    image_uri: ghcr.io/org/backenderer-api:1.2.3
  - name: web
    server_name: web.example.com
    container_port: 3000
    image_uri: ghcr.io/org/backenderer-web:2.3.4
```

#### Registry Behavior

- registry: ecr → images tagged as <ecr_repo_url>:<app-name>

- registry: ghcr → images tagged as ghcr.io/<owner>/<image_prefix><name>:<short-sha>



#### TLS Options

- Set in envs/dev/variables.tf or tfvars:

- none → plain HTTP

- letsencrypt → EC2 runs Certbot & auto-renews

- alb_acm → Application Load Balancer with ACM certs

## `infra/docs/troubleshooting.md`


# Troubleshooting Guide

### OIDC Role Error
- Check `AWS_ROLE_TO_ASSUME` is set correctly in GitHub Secrets
- Run `aws sts get-caller-identity` in your GitHub Actions logs

### SSM Command Timeout
- Confirm EC2 has `Backenderer=<env>` tag
- Check IAM role policy condition matches your env (`dev` / `prod`)

### Nginx Reload Failure
- `register.sh` validates config before reload
- See CloudWatch logs: `/var/log/nginx/error.log`

### Health Check Fails
- Make sure your app responds to `/backenderer/health`
- If using TLS=letsencrypt, certbot may take 1–2 minutes to complete

### TLS Errors
- Let's Encrypt: rate limits → switch to `dns-01` mode if testing a lot
- ALB/ACM: cert must be validated in Route53



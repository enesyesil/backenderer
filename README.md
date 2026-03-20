# Backenderer

Backenderer is a lightweight AWS deployment template for running a single backend app per deploy on an EC2 host with Docker and Nginx.

## What it does
- Provisions AWS infrastructure with Terraform
- Uses GitHub Actions + OIDC for infra, deploy, and destroy workflows
- Registers app containers on the host through AWS Systems Manager
- Supports two deploy modes:
  - `source`: build from `./app`
  - `image`: deploy any prebuilt image URI

## Repo layout
- `backenderer.config.yaml`: canonical deploy config consumed by workflows
- `app/`: source build context for `mode: source`
- `examples/single-app.yaml`: source-mode example config
- `infra/terraform/envs/{dev,prod}`: environment roots
- `infra/terraform/modules/`: shared Terraform modules
- `infra/docs/`: quickstart, remote state, and cost notes
- `scripts/`: host bootstrap and app registration scripts
- `.github/workflows/`: `infra`, `deploy`, and `remove`

## Deploy config
`backenderer.config.yaml` is the single deploy contract:

```yaml
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  server_name: _
  image_uri: nginx:1.27-alpine
```

Source mode uses `./app` and requires `app/Dockerfile`.

## Quickstart
### 1. Configure remote Terraform state
Backenderer uses remote S3 state by default.

For local Terraform runs:

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl
# edit backend.hcl with your bucket and region
terraform init -backend-config=backend.hcl
```

### 2. Configure env-specific GitHub secrets and variables
Required secrets:
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_PROD`

Required repository or environment variables:
- `TFSTATE_BUCKET`
- `TFSTATE_REGION`
- `AWS_REGION_DEV`
- `AWS_REGION_PROD`
- `DEV_AMI_ID`
- `DEV_INSTANCE_TYPE`
- `DEV_NAME_PREFIX`
- `DEV_TLS_MODE`
- `DEV_ROUTE53_ZONE_ID`
- `DEV_INSTANCE_PROFILE`
- `PROD_AMI_ID`
- `PROD_INSTANCE_TYPE`
- `PROD_NAME_PREFIX`
- `PROD_TLS_MODE`
- `PROD_ROUTE53_ZONE_ID`
- `PROD_INSTANCE_PROFILE`

`server_name` comes from `backenderer.config.yaml`.

### 3. Plan or apply infrastructure
Use the `Infra` workflow for CI-driven plans and applies.

For local Terraform runs, start from the checked-in tfvars examples:

```bash
cd infra/terraform/envs/dev
cp dev.tfvars.example dev.tfvars
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
```

### 4. Deploy the app
Use the `Deploy` workflow with `env=dev` or `env=prod`.

- `mode: source` builds `./app`, pushes to the env ECR repo, and registers that image on the host
- `mode: image` skips the build and registers the provided image URI directly

### 5. Verify success
Backenderer exposes a built-in host health endpoint:

```bash
curl http://<instance-public-ip>/backenderer/health
```

The deploy workflow also waits for the SSM registration command and fails on host-side errors.

## TLS support
Supported modes for this pass:
- `none`
- `alb_acm`

`letsencrypt` is intentionally not part of the current public contract.

## Destroy behavior
The `Remove Stack` workflow now performs a full Terraform destroy for the selected environment and requires an explicit confirmation input.

## Security checks
The `Security` workflow runs on pull requests and relevant pushes.

- Secret scanning: Trivy filesystem secret scan fails the workflow on detected secrets.
- Terraform/IaC scanning: Trivy config scan uploads `HIGH` and `CRITICAL` findings to GitHub code scanning.

## Docs
- [Config Reference](infra/docs/quickstart.md)
- [Deploy Config Schema](docs/CONFIG.md)
- [Remote State Guide](infra/docs/state.md)
- [Cost Notes](infra/docs/cost.md)

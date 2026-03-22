# Backenderer

Backenderer is a lightweight AWS deployment template for running a single backend app per environment on an EC2 host with Docker and Nginx.

## What it does
- Provisions AWS infrastructure with Terraform
- Uses GitHub Actions + OIDC for infra, deploy, and destroy workflows
- Registers app containers on the host through AWS Systems Manager
- Supports two deploy modes:
  - `source`: build from `./app` and publish to the managed env-scoped ECR repo
  - `image`: deploy a prebuilt image URI directly

## Repo layout
- `backenderer.config.yaml`: canonical deploy config consumed by workflows
- `app/`: source build context for `mode: source`
- `examples/single-app.yaml`: source-mode example config
- `bootstrap/`: one-time Terraform bootstrap for remote state + shared GitHub OIDC provider
- `infra/terraform/envs/{dev,prod}`: environment roots
- `infra/terraform/modules/`: shared Terraform modules
- `infra/docs/`: quickstart, bootstrap, remote state, and cost notes
- `scripts/`: host bootstrap and app registration scripts
- `.github/workflows/`: `infra`, `deploy`, `remove`, and `security`

## Deploy config
`backenderer.config.yaml` is the single deploy contract:

```yaml
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: /
  server_name: _
  image_uri: nginx:1.27-alpine
```

`health_path` is optional and defaults to `/`. The deploy workflow and ALB target group both use it as the application success signal.

## Quickstart
### 1. Run bootstrap once
Start with the bootstrap guide:

- [Bootstrap Guide](infra/docs/bootstrap.md)

That flow creates:
- the shared Terraform state bucket
- the shared GitHub OIDC provider ARN

The per-environment GitHub Actions role ARNs are created by the `dev` and `prod` env stacks and then stored in GitHub secrets.

### 2. Configure GitHub secrets and variables
Required secrets:
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_PROD`

Required repository or environment variables:
- `TFSTATE_BUCKET`
- `TFSTATE_REGION`
- `GITHUB_OIDC_PROVIDER_ARN`
- `AWS_REGION_DEV`
- `AWS_REGION_PROD`
- `DEV_AMI_ID`
- `PROD_AMI_ID`

Optional variables with defaults:
- `DEV_INSTANCE_TYPE` default `t3.micro`
- `PROD_INSTANCE_TYPE` default `t3.small`
- `DEV_NAME_PREFIX` default `backenderer`
- `PROD_NAME_PREFIX` default `backenderer`
- `DEV_TLS_MODE` default `none`
- `PROD_TLS_MODE` default `alb_acm`

Conditional variables:
- `DEV_ROUTE53_ZONE_ID` required only when `server_name` is a real DNS name and DNS records should be created
- `PROD_ROUTE53_ZONE_ID` required only for DNS-backed `alb_acm`
- `DEV_INSTANCE_PROFILE` only if you are reusing an existing instance profile
- `PROD_INSTANCE_PROFILE` only if you are reusing an existing instance profile

### 3. Plan or apply infrastructure
Use the `Infra` workflow for CI-driven plans and applies.

For local Terraform runs:

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl
cp dev.tfvars.example dev.tfvars
# edit backend.hcl + dev.tfvars with bootstrap outputs and env values
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
```

### 4. Deploy the app
Use the `Deploy` workflow with `env=dev` or `env=prod`.

- `mode: source` builds `./app`, pushes to `backenderer-apps-<env>`, and registers that image on the host
- `mode: image` skips the build and registers the provided image URI directly
- Private authenticated registry support in this repo is limited to ECR

### 5. Verify success
The deploy workflow now treats success as:
- SSM registration command succeeds
- the configured `deploy.health_path` returns success through the app vhost

For `alb_acm`, the same `health_path` is also used by the ALB target group.

## TLS support
Supported modes:
- `none`
- `alb_acm`

`none` keeps a single public EC2 host and no ALB.
`alb_acm` creates a public ALB and a private EC2 host behind it.

## Destroy behavior
The `Remove Stack` workflow performs a full Terraform destroy for the selected environment and requires an explicit confirmation input.

## Security checks
The `Security` workflow runs on pull requests and relevant pushes.

- Secret scanning: Trivy filesystem secret scan fails the workflow on detected secrets.
- Terraform/IaC scanning: Trivy config scan summarizes `HIGH` and `CRITICAL` findings in the workflow summary.

## Docs
- [Bootstrap Guide](infra/docs/bootstrap.md)
- [Quickstart](infra/docs/quickstart.md)
- [Config Reference](docs/CONFIG.md)
- [Deploy Config Schema](docs/config.schema.json)
- [Remote State Guide](infra/docs/state.md)
- [Cost Notes](infra/docs/cost.md)

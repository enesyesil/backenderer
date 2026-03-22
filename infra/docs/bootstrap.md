# Backenderer Bootstrap Guide

Use this flow once per AWS account and GitHub repository before the CI workflows can manage environments.

## 1. Create the shared bootstrap resources

```bash
cd bootstrap
terraform init
terraform apply -var='project=backenderer'
```

This creates:
- the Terraform state bucket
- the shared GitHub OIDC provider

Capture the outputs:

```bash
terraform output -raw state_bucket
terraform output -raw region
terraform output -raw oidc_provider_arn
```

## 2. Wire bootstrap outputs into GitHub variables
Set repository or environment variables:

- `TFSTATE_BUCKET` = `terraform output -raw state_bucket`
- `TFSTATE_REGION` = `terraform output -raw region`
- `GITHUB_OIDC_PROVIDER_ARN` = `terraform output -raw oidc_provider_arn`

Also set:
- `AWS_REGION_DEV`
- `AWS_REGION_PROD`
- `DEV_AMI_ID`
- `PROD_AMI_ID`

Optional with defaults:
- `DEV_INSTANCE_TYPE`
- `PROD_INSTANCE_TYPE`
- `DEV_NAME_PREFIX`
- `PROD_NAME_PREFIX`
- `DEV_TLS_MODE`
- `PROD_TLS_MODE`

Conditional:
- `DEV_ROUTE53_ZONE_ID`
- `PROD_ROUTE53_ZONE_ID`
- `DEV_INSTANCE_PROFILE`
- `PROD_INSTANCE_PROFILE`

## 3. Create the per-environment GitHub Actions roles
Run the env stack once with credentials that can create IAM, network, compute, ECR, Route53, ACM, and ALB resources.

Example for `dev`:

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl
cp dev.tfvars.example dev.tfvars
# edit backend.hcl and dev.tfvars with bootstrap outputs and env values
terraform init -backend-config=backend.hcl
terraform apply -var-file=dev.tfvars
```

Capture the env role ARN:

```bash
terraform output -raw role_arn
```

Repeat for `prod`.

## 4. Wire the env role ARNs into GitHub secrets
Set repository or environment secrets:

- `AWS_ROLE_ARN_DEV` = `infra/terraform/envs/dev` output `role_arn`
- `AWS_ROLE_ARN_PROD` = `infra/terraform/envs/prod` output `role_arn`

After this, the `Infra`, `Deploy`, and `Remove Stack` workflows can assume the per-environment roles through GitHub OIDC.

## 5. Sanity-check the repo contract
Before relying on CI, run the local checks that mirror the workflow validate job:

```bash
bash -n scripts/bootstrap.sh scripts/register.sh scripts/unregister.sh
terraform -chdir=bootstrap init -backend=false
terraform -chdir=bootstrap validate
terraform -chdir=infra/terraform/envs/dev init -backend=false
terraform -chdir=infra/terraform/envs/dev validate
terraform -chdir=infra/terraform/envs/prod init -backend=false
terraform -chdir=infra/terraform/envs/prod validate
```

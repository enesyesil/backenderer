# Backenderer Quickstart

## 1. Pick a deploy mode
Backenderer supports one app per deploy.

`mode: source`
- Build from `./app`
- Requires `app/Dockerfile`
- Pushes to the env ECR repo before registration

`mode: image`
- Uses a prebuilt image URI
- Skips build and push

## 2. Edit `backenderer.config.yaml`
Example:

```yaml
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  server_name: _
  image_uri: nginx:1.27-alpine
```

Use `_` when you want a catch-all host. Use a real DNS name when you plan to create Route53 records or `alb_acm` resources.

## 3. Configure remote state
Backenderer uses remote S3 state by default.

Local setup:

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl
# edit backend.hcl
terraform init -backend-config=backend.hcl
```

CI setup:
- `TFSTATE_BUCKET`
- `TFSTATE_REGION`

## 4. Configure GitHub secrets and variables
Secrets:
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_PROD`

Variables:
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

`server_name` is read from `backenderer.config.yaml`.

## 5. Run infrastructure
Use the `Infra` workflow for plans and applies.

For local runs, copy the env example and supply backend config:

```bash
cd infra/terraform/envs/dev
cp dev.tfvars.example dev.tfvars
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
```

## 6. Deploy
Use the `Deploy` workflow with `env=dev` or `env=prod`.

The workflow will:
- validate the config
- build or select the image
- register the app on the host over SSM
- wait for command completion
- run a host health check

## 7. Destroy
Use the `Remove Stack` workflow when you want a full Terraform destroy.

You must type the selected env name again in `confirm_env` before destroy is allowed.

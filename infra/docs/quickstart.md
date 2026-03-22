# Backenderer Quickstart

## 1. Bootstrap shared prerequisites
Run the one-time bootstrap flow first:

- [Bootstrap Guide](bootstrap.md)

That creates the Terraform state bucket and the shared GitHub OIDC provider ARN that the env stacks consume.

## 2. Pick a deploy mode
Backenderer supports one app per environment.

`mode: source`
- Build from `./app`
- Requires `app/Dockerfile`
- Pushes to the managed env ECR repository `backenderer-apps-<env>`

`mode: image`
- Uses a prebuilt image URI
- Skips build and push
- Private authenticated registry support is limited to ECR

## 3. Edit `backenderer.config.yaml`
Example:

```yaml
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: /
  server_name: _
  image_uri: nginx:1.27-alpine
```

Use `_` when you want a catch-all host.
Use a real DNS name when you plan to create Route53 records or `alb_acm` resources.

## 4. Configure GitHub secrets and variables
Required secrets:
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_PROD`

Required variables:
- `TFSTATE_BUCKET`
- `TFSTATE_REGION`
- `GITHUB_OIDC_PROVIDER_ARN`
- `AWS_REGION_DEV`
- `AWS_REGION_PROD`
- `DEV_AMI_ID`
- `PROD_AMI_ID`

Optional variables with defaults:
- `DEV_INSTANCE_TYPE`
- `PROD_INSTANCE_TYPE`
- `DEV_NAME_PREFIX`
- `PROD_NAME_PREFIX`
- `DEV_TLS_MODE`
- `PROD_TLS_MODE`

Conditional variables:
- `DEV_ROUTE53_ZONE_ID`
- `PROD_ROUTE53_ZONE_ID`
- `DEV_INSTANCE_PROFILE`
- `PROD_INSTANCE_PROFILE`

`server_name` and `health_path` are read from `backenderer.config.yaml`.

## 5. Run infrastructure
Use the `Infra` workflow for plans and applies.

For local runs:

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl
cp dev.tfvars.example dev.tfvars
# edit backend.hcl + dev.tfvars
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
```

## 6. Deploy
Use the `Deploy` workflow with `env=dev` or `env=prod`.

The workflow will:
- validate the deploy config
- build or select the image
- register the app on the host over SSM
- wait for command completion
- fail if the configured `health_path` is not healthy through Nginx

## 7. Destroy
Use the `Remove Stack` workflow for a full Terraform destroy.

You must type the selected env name again in `confirm_env` before destroy is allowed.

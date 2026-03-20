# Terraform State

Backenderer uses remote S3 state by default.

## Local setup
Each env includes a `backend.hcl.example` file:

- `infra/terraform/envs/dev/backend.hcl.example`
- `infra/terraform/envs/prod/backend.hcl.example`

Typical local flow:

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl
# edit backend.hcl
terraform init -backend-config=backend.hcl
```

## CI setup
The GitHub workflows inject backend settings at init time from:
- `TFSTATE_BUCKET`
- `TFSTATE_REGION`

The state key is fixed by environment:
- `envs/dev/terraform.tfstate`
- `envs/prod/terraform.tfstate`

## Notes
- State locking uses the S3 lockfile support built into Terraform.
- There is no local-state-first path in the main docs anymore.
- `.tfstate` files remain gitignored and should never be committed.

# Terraform State (Local vs Remote)

**Note:** This repo is stateless by default. For quick testing or single-user setups, local state is fine.
For production or team use, always enable a remote backend (S3 + DynamoDB) to ensure durability, collaboration, and state locking.

## Quick options

### 1) Local state (default)
- Do nothing. `terraform init` will use the local backend.
- Never commit `.tfstate` (repo already ignores it).

### 2) Remote state (recommended for prod)
1. Create:
   - S3 bucket (enable Versioning), e.g. `my-tfstate-bucket`
   - DynamoDB table for locks, e.g. `terraform-locks` (PK: `LockID` string)
2. Choose one:
   - **File-based:** copy `backend.tf.example → backend.tf` in the env folder and fill values.
   - **CI-based:** set GitHub secrets (see below) and let the workflow pass `-backend-config`.

## CI secrets (optional)
- `TFSTATE_BUCKET` = your S3 bucket
- `TF_LOCK_TABLE` = your DynamoDB table
- `AWS_REGION`    = region of the bucket/table

If set, the Infra workflow will initialize Terraform with remote backend automatically.

## Migrate from local → remote
From your machine (recommended):
```bash
cd infra/terraform/envs/<dev|prod>
terraform init -migrate-state
```


### Roll back to local (not recommended for prod)

Remove/rename backend.tf and:
```bash
terraform init -migrate-state -force-copy
```


## Conditional `terraform init` in CI (so forks “just work”)
In your **Infra** workflow where you run Terraform, swap the init step to this conditional version:

```yaml
- name: Terraform Init (local or remote)
  run: |
    set -e
    TF_DIR="infra/terraform/envs/${{ inputs.env }}"
    if [ -n "${{ secrets.TFSTATE_BUCKET }}" ] && [ -n "${{ secrets.TF_LOCK_TABLE }}" ]; then
      echo "Using remote backend (S3 + DynamoDB)"
      terraform -chdir="$TF_DIR" init \
        -backend-config="bucket=${{ secrets.TFSTATE_BUCKET }}" \
        -backend-config="key=backenderer/${{ inputs.env }}/terraform.tfstate" \
        -backend-config="region=${{ secrets.AWS_REGION }}" \
        -backend-config="dynamodb_table=${{ secrets.TF_LOCK_TABLE }}" \
        -backend-config="encrypt=true"
    else
      echo "Using local backend"
      terraform -chdir="$TF_DIR" init
    fi
```

## Ensure state files are ignored

Double-check your .gitignore (root of repo) has:

# Terraform
*.tfstate
*.tfstate.backup
.terraform/
.crash
override.tf
override.tf.json
*_override.tf
*_override.tf.json
# Verification Matrix

Use this as the default definition of done for small repo changes.

| Change | Run | Expected signal |
| --- | --- | --- |
| Deploy config or docs | `./scripts/validate_config.sh backenderer.config.yaml` | Config validates successfully |
| Shell helpers or host scripts | `./tests/run.sh` | All shell tests pass |
| Terraform modules or env roots | `terraform fmt -check -recursive` | No formatting drift |
| Terraform modules or env roots | `./scripts/preflight.sh` | Preflight reaches the end successfully |
| Workflow or repo-wide changes | `./scripts/preflight.sh` | Shell tests, Terraform validate, and Terraform tests all pass |

## Notes
- `./scripts/preflight.sh` is the fastest full-repo safety check.
- The deploy workflow expects exactly one running EC2 instance tagged `Backenderer=<env>`.
- Failed rollout tests should leave the current live vhost and `apps.json` entry unchanged.

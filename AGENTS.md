# Backenderer Agent Guide

## Entry points
- `bootstrap/`: one-time shared AWS prerequisites.
- `infra/terraform/envs/{dev,prod}`: per-environment Terraform roots.
- `.github/workflows/infra.yml`: validate, plan, and apply infrastructure.
- `.github/workflows/deploy.yml`: build/select an image and register it on the host.
- `.github/workflows/remove.yml`: destroy an environment.

## Default verification
- `./scripts/preflight.sh`
- `./scripts/validate_config.sh backenderer.config.yaml`
- `./tests/run.sh`

## Hidden invariants worth knowing
- The GitHub OIDC env roles only trust `refs/heads/main` by default.
- `deploy.health_path` is the success signal for both deploy registration and ALB target-group health checks.
- `deploy.server_name` must be `_` or a single hostname/wildcard hostname.
- The repo is optimized for one backend app per environment.

## Safe to change
- Docs in `docs/` and `infra/docs/`
- Shell helpers in `scripts/`
- Tests in `tests/`

## Risky to change
- `scripts/register.sh`: directly affects cutover behavior on the live host.
- `infra/terraform/modules/iam_github_oidc`: controls CI blast radius.
- `infra/terraform/modules/compute_vm_docker_nginx`: changes host boot/security defaults.
- Workflow dispatch behavior and required GitHub secrets/variables.

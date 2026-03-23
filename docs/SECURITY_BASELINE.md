# Security Baseline

## Current posture
- The security workflow fails on detected secrets.
- Terraform/IaC findings are summarized but intentionally non-blocking for now.
- EC2 instances require IMDSv2.
- GitHub Actions SSM command access is scoped by the `Backenderer=<env>` instance tag.

## Planned enforcement
- Keep Trivy config scan non-blocking until the existing baseline is reviewed and cleaned up.
- After the baseline is clean, change the Trivy config scan `--exit-code` from `0` to `1` in `.github/workflows/security.yml` to enforce `HIGH` and `CRITICAL` findings.

## Review checklist before flipping to blocking
- Confirm no accepted `HIGH` or `CRITICAL` findings remain.
- Confirm the workflow is required in branch protection.
- Announce the enforcement date so contributors are not surprised by newly blocking checks.

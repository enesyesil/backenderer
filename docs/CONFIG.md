# Backenderer Config

One YAML drives deploys. Use single-app or multi-app.

## Top-level keys
- `multi_app`: `false` for single-app, `true` for multi.
- `mode`: `source` (build from `./app`) or `image` (use `image_uri`).
- `registry`: `ecr` or `ghcr`.
- `image_prefix`: string prefix for GHCR tags in `mode=source` (e.g., `svc-`).
- `tls_email`: email used for Let's Encrypt when infra `tls_mode=letsencrypt`.

### Single-app
```yaml
multi_app: false
mode: source
registry: ecr
name: hello
server_name: hello.example.com
container_port: 8080
# image_uri: ... (required if mode=image)
```
### Multi-app
```yaml
multi_app: true
mode: image
registry: ghcr
image_prefix: svc-
apps:
  - { name: api, server_name: api.example.com, container_port: 8000, image_uri: ghcr.io/org/api:1.0 }
  - { name: web, server_name: web.example.com, container_port: 3000, image_uri: ghcr.io/org/web:2.0 }
```
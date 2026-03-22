# Backenderer Config

`backenderer.config.yaml` is the single source of truth for app deploys.

## Schema
- `deploy.mode`: `source` or `image`
- `deploy.app_name`: lowercase app slug used for the container name and image tag
- `deploy.container_port`: container port exposed by the app
- `deploy.health_path`: optional application health-check path; defaults to `/`
- `deploy.server_name`: nginx `server_name`; use `_` for a catch-all host, otherwise use a single hostname or wildcard hostname such as `api.example.com` or `*.example.com`
- `deploy.image_uri`: required when `deploy.mode = image`

## Source Mode
Use source mode when the repo contains `app/Dockerfile`.
Backenderer will build `./app`, push it to the managed env-scoped ECR repository `backenderer-apps-<env>`, and register that image on the host.

```yaml
deploy:
  mode: source
  app_name: hello-web
  container_port: 8080
  health_path: /health
  server_name: hello.example.com
```

## Image Mode
Use image mode when you want to deploy a prebuilt image.
Private authenticated registry support in this repo is limited to ECR.

```yaml
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: /
  server_name: _
  image_uri: nginx:1.27-alpine
```

## Local verification
Run `./scripts/validate_config.sh backenderer.config.yaml` to verify the config contract locally.

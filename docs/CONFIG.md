# Backenderer Config

`backenderer.config.yaml` is the single source of truth for app deploys.

## Schema
- `deploy.mode`: `source` or `image`
- `deploy.app_name`: lowercase app slug used for the container name and image tag
- `deploy.container_port`: container port exposed by the app
- `deploy.server_name`: nginx `server_name`; use `_` for a catch-all host
- `deploy.image_uri`: required when `deploy.mode = image`

## Source Mode
Use source mode when the repo contains `app/Dockerfile`.

```yaml
deploy:
  mode: source
  app_name: hello-web
  container_port: 8080
  server_name: hello.example.com
```

## Image Mode
Use image mode when you want to deploy a prebuilt image from any registry.

```yaml
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  server_name: _
  image_uri: nginx:1.27-alpine
```

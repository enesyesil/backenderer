#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-backenderer.config.yaml}"

ruby -rjson -ryaml -e '
  config_path = ARGV.fetch(0)
  data = YAML.safe_load(
    File.read(config_path),
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false,
  ) || {}

  deploy = data["deploy"] || {}
  health_path = deploy.key?("health_path") && !deploy["health_path"].nil? ? deploy["health_path"] : "/"
  image_uri = deploy.key?("image_uri") && !deploy["image_uri"].nil? ? deploy["image_uri"] : ""

  result = {
    mode: deploy["mode"],
    app_name: deploy["app_name"],
    app_port: deploy["container_port"],
    server_name: deploy["server_name"],
    image_uri: image_uri,
    health_path: health_path,
  }

  puts JSON.generate(result)
' "$CONFIG_PATH"

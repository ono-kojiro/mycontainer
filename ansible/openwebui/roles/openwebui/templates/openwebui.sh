#!/bin/sh

# https://docs.openwebui.com/getting-started/env-configuration/

# WEBUI_URL
# PORT: (can not set!)

. /etc/openwebui/openwebui.conf

cd /var/lib/openwebui

export DATA_DIR=/var/lib/openwebui
export WEBUI_URL=http://192.168.0.98:8080


/var/lib/openwebui/.local/bin/uvx cache prune --ci

exec /var/lib/openwebui/.local/bin/uvx --python 3.11 \
  open-webui@latest serve --port 8080


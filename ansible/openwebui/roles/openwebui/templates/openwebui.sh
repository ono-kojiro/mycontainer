#!/bin/sh

# https://docs.openwebui.com/getting-started/env-configuration/

# WEBUI_URL
# PORT: (can not set!)

. /var/lib/openwebui/pyenv/pyenv.shrc
cd /var/lib/openwebui

DATA_DIR=/var/lib/openwebui
WEBUI_URL=http://192.168.0.98:8080

#exec /var/lib/openwebui/.local/bin/uvx --python 3.11 open-webui@latest serve --port 8080
exec /var/lib/openwebui/.local/bin/uvx --python 3.11 open-webui@0.5.17 serve --port 8080


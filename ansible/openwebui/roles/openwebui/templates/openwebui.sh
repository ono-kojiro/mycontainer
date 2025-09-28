#!/bin/sh

# https://docs.openwebui.com/getting-started/env-configuration/

# WEBUI_URL
# PORT: (can not set!)

. {{ openwebui_confdir }}/{{ openwebui_conf }}

export DATA_DIR={{ openwebui_datadir }}
export WEBUI_URL={{ openwebui_url }}

cd ${DATA_DIR}

${DATA_DIR}/.local/bin/uvx cache prune

exec ${DATA_DIR}/.local/bin/uvx --python {{ python_version }} \
  open-webui@latest serve --port {{ openwebui_port }}


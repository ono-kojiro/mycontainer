#!/bin/sh

. /var/lib/openwebui/pyenv/pyenv.shrc
cd /var/lib/openwebui

DATA_DIR=/var/lib/openwebui
exec /var/lib/openwebui/.local/bin/uvx --python 3.11 open-webui@latest serve


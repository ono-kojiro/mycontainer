#!/bin/sh

service="wayvnc"

mkdir -p $HOME/.config/systemd/user/
cp -f ${service}.service $HOME/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable ${service}
systemctl --user start ${service}


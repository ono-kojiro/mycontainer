#!/bin/sh

. ./config.bashrc

echo "1..1"

image_dir=/var/lib/docker-registry/docker/registry/v2/repositories/myimage
sudo rm -rf $image_dir
res=$?

if [ "$res" = "0" ]; then
  echo "ok"
else
  echo "not ok"
fi

sudo systemctl restart docker-registry


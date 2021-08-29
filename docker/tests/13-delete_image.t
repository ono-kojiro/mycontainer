#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

registry='192.168.7.1:5000'
name='myimage'
curl -v -sSL -X DELETE "http://${registry}/v2/${name}/manifests/$(
    curl -sSL -I \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "http://${registry}/v2/${name}/manifests/$(
            curl -sSL "http://${registry}/v2/${name}/tags/list" | jq -r '.tags[0]'
        )" \
    | awk '$1 == "Docker-Content-Digest:" { print $2 }' \
    | tr -d $'\r' \
)"

res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registory delete passed"
else
  echo "not ok - docker-registory delete failed"
fi


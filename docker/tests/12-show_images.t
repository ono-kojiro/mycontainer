#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..3"

curl -X GET http://192.168.7.1:5000/v2/_catalog > repositories.json 2>/dev/null
res=$?
echo ""
cat repositories.json
if [ "$res" = "0" ]; then
  echo "ok - docker-registory catalog passed"
else
  echo "not ok - docker-registory catalog failed"
fi

num_repos=`cat repositories.json | jq '.repositories | length'`

if [ "$num_repos" != "0" ]; then
  curl -X GET http://192.168.7.1:5000/v2/myimage/tags/list > tags.json 2> /dev/null
  res=$?
  echo ""
  cat tags.json
  if [ "$res" = "0" ]; then
    echo "ok - docker-registry tags/list passed"
  else
    echo "not ok - docker-registry tags/list failed"
  fi
else
  echo "ok - no repository # SKIP docker-registry tags/list"
fi

if [ "$num_repos" != "0" ]; then
  curl -X GET \
    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    -s -D - http://192.168.7.1:5000/v2/myimage/manifests/latest \
  | grep Docker-Content-Digest:

  res=$?
  echo ""
  if [ "$res" = "0" ]; then
    echo "ok - docker-registry digest passed"
  else
    echo "not ok - docker-registry digest failed"
  fi
else
  echo "ok - no repository # SKIP docker-registry digest"
fi


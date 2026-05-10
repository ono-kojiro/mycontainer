#!/bin/sh

. ../.env

access_token_json="../access_token.json"
token=`cat $access_token_json | jq -r ".access_token"`

delete()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
    -X DELETE https://${COUCHDB_HTTPS}/mydb > $0.json
  if [ "$?" -eq 0 ]; then
    echo "ok - curl"
  else
    echo "not ok - curl"
  fi

  res=`cat $0.json | jq -r ".ok"`
  if [ "$res" = "true" ]; then
    echo "ok - couchdb"
  else
    echo "not ok - couchdb, $err"
  fi
}

delete


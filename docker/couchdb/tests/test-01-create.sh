#!/bin/sh

. ../.env

access_token_json="../access_token.json"
token=`cat $access_token_json | jq -r ".access_token"`

echo "1..2"

create()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
    -X PUT https://${COUCHDB_HTTPS}/mydb > $0.json
  if [ "$?" -eq 0 ]; then
    echo "ok - curl"
  else
    echo "not ok - curl"
  fi

  res=`cat $0.json | jq -r ".ok"`
  errmsg=`cat $0.json | jq -r ".error"`

  if [ "$res" = "true" ] ; then
    echo "ok - create mydb"
  elif [ "$errmsg" = "file_exists" ] ; then
    echo "ok - mydb file_exists"
  else
    echo "not ok - couchdb, $err"
  fi
}

create


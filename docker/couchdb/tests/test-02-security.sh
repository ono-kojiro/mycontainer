#!/bin/sh

. ../.env

access_token_json="../access_token.json"
token=`cat $access_token_json | jq -r ".access_token"`

echo "1..7"

security()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
    -X GET https://${COUCHDB_HTTPS}/mydb/_security > $0.json
  if [ "$?" -eq 0 ]; then echo "ok - curl"; else echo "not ok - curl"; fi
  
  res=`cat $0.json | jq -r ".admins"`
  if [ ! -z "$res" ]; then
    echo "ok - couchdb"
  else
    echo "not ok - couchdb, $err"
  fi

  res=`cat $0.json | jq -r ".members"`
  if [ ! -z "$res" ]; then
    echo "ok - couchdb"
  else
    echo "not ok - couchdb, $err"
  fi
}

set_security()
{
  name=`cat ../session.json | jq -r '.userCtx.name'`
    
  data=`cat << EOF
{
  "admins": {
    "names": [ "$name" ],
    "roles": [ "_admins" ]
  },
  "members": {
    "names": [ "$name" ],
    "roles": [ "developer" ]
  }
}
EOF
`

  curl -s -X PUT \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
    -H "Content-Type: Application/json" \
    https://${COUCHDB_HTTPS}/mydb/_security \
    -d "${data}"

  if [ "$?" -eq 0 ]; then echo "ok - curl"; else echo "not ok - curl"; fi
}

check_security()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
    -X GET https://${COUCHDB_HTTPS}/mydb/_security > $0.json
  if [ "$?" -eq 0 ]; then echo "ok - curl"; else echo "not ok - curl"; fi
  
  res=`cat $0.json | jq -r ".admins"`
  if [ ! -z "$res" ]; then
    echo "ok - couchdb"
  else
    echo "not ok - couchdb, $err"
  fi

  res=`cat $0.json | jq -r ".members"`
  if [ ! -z "$res" ]; then
    echo "ok - couchdb"
  else
    echo "not ok - couchdb, $err"
  fi
}

security
set_security
check_security


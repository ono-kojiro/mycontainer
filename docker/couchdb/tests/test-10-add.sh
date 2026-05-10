#!/bin/sh

. ../.env

access_token_json="../access_token.json"
token=`cat $access_token_json | jq -r ".access_token"`

echo "1..3"

db="mydb"
doc="mydoc"

all_dbs()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
    -X GET https://${COUCHDB_HTTPS}/_all_dbs > $0.json
  if [ "$?" -eq 0 ]; then
    echo "ok - curl"
  else
    echo "not ok - curl"
  fi

  res=`cat $0.json | jq -r ".[0]"`
  if [ "$res" = "mydb" ]; then
    echo "ok - mydb exists"
  else
    echo "not ok - mydb does NOT exists, $err"
  fi
}

get_doc_rev()
{
  url="https://${COUCHDB_HTTPS}/${db}/${doc}"
  header="Authorization: Bearer $token"

  curl -s -k \
    -H "$header" \
    -X GET "$url" >${doc}.json 2>/dev/null

  #echo -n "DEBUG: " 1>&2
  #cat ${doc}.json 1>&2

  _rev=`cat ${doc}.json | jq -r '._rev'`
  if [ "$_rev" = "null" ]; then
    _rev=""
  fi
  echo "$_rev"
}

get_doc_count()
{
  url="https://${COUCHDB_HTTPS}/${db}/${doc}"
  header="Authorization: Bearer $token"

  count=`curl -s -k -H "$header" -X GET "$url" | jq -r '.count'`
  if [ "$count" = "null" ]; then
    count="0"
  fi
  echo "$count"
}

add()
{
  _rev=`get_doc_rev`
  count=`get_doc_count`

  count=`expr $count + 1`

  if [ -z "$_rev" ]; then
    data=`cat << EOF
{
  "name":"hoge",
  "value":"foo",
  "count": $count
}
EOF
`
  else
    data=`cat << EOF
{
  "_rev": "$_rev",
  "name":"hoge",
  "value":"foo",
  "count": $count
}
EOF
`
  fi

  curl -s -k \
    -H "Authorization: Bearer $token" \
    -X PUT https://${COUCHDB_HTTPS}/${db}/${doc} \
    -d "${data}"

  if [ "$?" -eq 0 ]; then
    echo "ok - put"
  else
    echo "not ok - put"
  fi
}

all_dbs
add


#!/bin/sh

docid="mydoc1"

cat - << EOF > ${docid}.json
{
  "_id": "mydoc1",
  "type": "device",
  "name": "My Device",
  "count": 1
}
EOF

api_key1=`cat ../hosts.yml \
  | yq -r ".all.children.servers.hosts.localhost.api_key1"`

api_user1=`cat ../hosts.yml \
  | yq -r ".all.children.servers.hosts.localhost.api_user1"`


echo "INFO: $api_user1"

curl \
  -H "X-API-Key: $api_key1" \
  -X DELETE \
  https://localhost/couchdb/mydb

curl \
  -H "X-API-Key: $api_key1" \
  -X PUT \
  https://localhost/couchdb/mydb

curl \
  -H "X-API-Key: $api_key1" \
  -X GET \
  https://localhost/couchdb/_all_dbs

echo "INFO: upload doc"
cat ${docid}.json

curl \
  -H "X-API-Key: $api_key1" \
  -H "Content-Type: application/json" \
  -d @${docid}.json \
  -X PUT \
  https://localhost/couchdb/mydb/${docid}

curl -s \
  -H "X-API-Key: $api_key1" \
  https://localhost/couchdb/mydb/${docid} | jq . > ${docid}-1.json

rev=`cat ${docid}-1.json | jq -r "._rev"`

count=`cat ${docid}-1.json | jq -r ".count"`
count=`expr $count + 1`
echo "INFO: rev is $rev"
echo "INFO: count is $count"

cat mydoc1-1.json | sed "s/\"count\": [0-9]*/\"count\": $count/" > ${docid}-2.json

echo "INFO: upload doc"
cat ${docid}-2.json

curl \
  -H "X-API-Key: $api_key1" \
  -H "Content-Type: application/json" \
  -d @${docid}-2.json \
  -X PUT \
  https://localhost/couchdb/mydb/${docid}?rev=$rev

curl -s \
  -H "X-API-Key: $api_key1" \
  https://localhost/couchdb/mydb/${docid} | jq . > ${docid}-2-got.json

echo "INFO : got doc"
cat ${docid}-2-got.json


#!/bin/sh

if [ ! -e "mytestkey.json" ]; then
  sh ../elasticsearch/api_key.sh create -n mytestkey | tee mytestkey.json
fi

encoded=`cat mytestkey.json | jq -r ".encoded"`

status()
{
  curl -s -k \
    --header "Authorization: ApiKey $encoded" \
    https://192.168.0.98:5601/api/status | jq
}

data_views()
{
  curl -s -k \
    --header "Authorization: ApiKey $encoded" \
    https://192.168.0.98:5601/api/data_views | jq
}

#status
data_views


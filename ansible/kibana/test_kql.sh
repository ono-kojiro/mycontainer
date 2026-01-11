#!/bin/sh

encoded=`cat mytestkey.json | jq -r ".encoded"`

status()
{
  curl -s -k \
    --header "Authorization: ApiKey $encoded" \
    https://192.168.0.98:5601/api/status | jq
}

query()
{
  curl -s -k \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -H "x-elastic-internal-origin: support-diagnostics" \
    -H "Authorization: ApiKey $encoded" \
    -X POST \
    https://192.168.0.98:5601/internal/search/es \
    -d ' {
      "params": {
        "index": "packetbeat-default-2025.12.*",
        "body": {
          "query": {
            "bool": {
              "filter": [
                 {
                    "query_string": {
                      "query": "source.ip: 192.168.0.98",
                      "default_operator": "AND"
                    }
                 } 
              ]
            }
          }
        },
        "size": 10
      }      
    }' | jq | tee output.json
}

status
query


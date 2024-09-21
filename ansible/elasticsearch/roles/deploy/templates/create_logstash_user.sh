#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

netrc="/tmp/.netrc"
es_host="https://{{ ansible_facts.default_ipv4.address }}:9200"

username="logstash_internal"
role="logstash_writer"

curl -k --netrc-file $netrc \
  -H 'Content-Type: application/json' \
  -XPOST "$es_host/_security/role/$role" --data @- << EOS
{
  "cluster": [ "manage_index_templates", "monitor", "manage_ilm" ],
  "indices": [
    {
      "names": [ "*" ],
      "privileges": [ "auto_configure", "create_index", "manage", "all" ]
    }
  ]
}
EOS
  
curl -k --netrc-file $netrc \
  -H 'Content-Type: application/json' \
  -XPOST "$es_host/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "logstash",
  "roles" : [ "$role"],
  "full_name" : "Internal Logstash User"
}
EOS


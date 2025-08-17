#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

rolename="logstash_writer"
username="logstash_internal"
  
es_url=`cat host_vars/logstash/main.yml | \
  grep -e '^elastic_url' | awk '{ print $2 }'`

es_netrc="../elasticsearch/.netrc"

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...
  createkey:
  deletekey:

  roleadd: add logstash_writer role in elasticsearch
  useradd: add logstash_internal user in elasticsearch

  reset:   reset password of logstash_internal in elasticsearch
  logstash: deploy logstash

  roledel: delete logstash_writer role
  useradd: delete logstash_internal user
EOS

}

all()
{
  deploy
}

clean()
{
  ansible-playbook -i hosts.yml clean.yml
}

hosts()
{
  ansible-inventory -i template.yml --list --yaml > hosts.yml
}

createkey()
{
  deletekey
  sh ../elasticsearch/api_key.sh create -n logstash > logstash.json
  api_key=`cat logstash.json | jq -r '.api_key'`
  api_key_id=`cat logstash.json | jq -r '.id'`
  api_key_name=`cat logstash.json | jq -r '.name'`

  cat - << EOF > host_vars/logstash/api_key.yml
---
api_key_id:   ${api_key_id}
api_key_name: ${api_key_name}
api_key:      ${api_key}
EOF

  rm -f logstash.json
}

deletekey()
{
  sh ../elasticsearch/api_key.sh delete -n logstash
}

roleadd()
{
  cat - << EOF > data.json
{
  "cluster": [ "manage_index_templates", "monitor", "manage_ilm" ],
  "indices": [
    {
      "names": [ "*" ],
      "privileges": [ "auto_configure", "create_index", "manage", "all" ]
    }
  ],
  "description" : "Custom role to create index of logstash"
}
EOF

  cmd="curl -k --netrc-file $es_netrc"
  cmd="$cmd -H \"Content-Type: application/json\""
  cmd="$cmd -X POST \"$es_url/_security/role/$rolename?pretty\""
  cmd="$cmd --data @data.json"
  echo $cmd
  eval $cmd
}

roledel()
{
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_url/_security/role/$rolename?pretty"
}

useradd()
{
  cat - << EOS > data.json
{
  "password" : "logstash",
  "roles" : [ "$rolename"],
  "full_name" : "Internal Logstash User"
}
EOS

  cmd="curl -k --netrc-file $es_netrc"
  cmd="$cmd -H \"Content-Type: application/json\""
  cmd="$cmd -XPOST \"$es_url/_security/user/$username?pretty\""
  cmd="$cmd --data @data.json"

  echo $cmd
  eval $cmd

  rm -f data.json
}

userdel()
{
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_url/_security/user/$username?pretty"
}

install()
{
  ansible-playbook $flags -i hosts.yml -t install site.yml
}


deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
}

reset()
{
  ansible-playbook $flags -i hosts.yml reset.yml
}


destroy()
{
  ansible-playbook $flags -i hosts.yml destroy.yml
}


test()
{
  #netrc="../elasticsearch/.netrc"
  netrc="./.netrc"
  machine=`cat $netrc | grep -e '^machine' | awk '{ print $2 }'`
  #cmd="curl -k --netrc-file $netrc https://${machine}:9200"
  flags=""
  flags="$flags --netrc-file $netrc"
  flags="$flags --cacert /usr/share/ca-certificates/mylocalca/mylocalca.crt"
  cmd="curl $flags https://${machine}:9200"
  echo $cmd
  $cmd
}


hosts

args=""
while [ $# -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    -* )
      flags="$flags $1"
      ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for arg in $args; do
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done


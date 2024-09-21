#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir
  
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

  roleadd: add logstash_writer role
  useradd: add logstash_internal user

  reset:   reset password of logstash_internal
  install: install logstash package
  deploy:  setup logstash


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

roleadd()
{
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/role/$rolename?pretty" --data @- << EOS
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
EOS

}

roledel()
{
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_url/_security/role/$rolename?pretty"
}

useradd()
{
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "logstash",
  "roles" : [ "$rolename"],
  "full_name" : "Internal Logstash User"
}
EOS

}

userdel()
{
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_url/_security/user/$username?pretty"
}

install()
{
  ansible-playbook -K -i hosts.yml -t install site.yml
}


deploy()
{
  ansible-playbook -K -i hosts.yml -t deploy site.yml
}

default()
{
  tag=$1
  ansible-playbook -K -i hosts.yml ${tag}.yml
}

test()
{
  machine=`cat .netrc | grep -e '^machine' | awk '{ print $2 }'`
  curl -k --netrc-file ./.netrc https://${machine}:9200
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


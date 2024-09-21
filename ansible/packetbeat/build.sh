#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

rolename="packetbeat_writer"
username="packetbeat_internal"

es_url=`cat host_vars/packetbeat/elasticsearch.yml | \
  grep -e '^elasticsearch_url' | awk '{ print $2 }'`

es_netrc="../elasticsearch/.netrc"

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

  roleadd     create packetbeat_writer role
  useradd     create packetbeat_internal user

  reset       reset beats_system password
  install     install packetbeat package
  deploy      deploy kibana


  roledel     delete packetbeat_writer role
  userdel     delete packetbeat_internal user
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
  "cluster": [ "manage_index_templates", "manage_ilm", "manage_ingest_pipelines", "monitor" ],
  "indices": [
    {
      "names": [ "packetbeat-*" ],
      "privileges": [ "auto_configure", "create_index", "create", "write" ]
    }
  ],
  "description" : "Custom role to create data streams of packetbeat"
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
  "password" : "packetbeat",
  "roles" : [ "$rolename", "kibana_admin" ],
  "full_name" : "Internal Packetbeat User"
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



install()
{
  echo "install is called"
  hosts
  cmd="ansible-playbook -K -i hosts.yml -t install site.yml"
  echo $cmd
  $cmd
}

deploy()
{
  cp -f ../kibana/host_vars/kibana/kibana_password.yml host_vars/packetbeat/
  hosts
  ansible-playbook -K -i hosts.yml -t deploy site.yml
}

reset()
{
  ansible-playbook -K -i hosts.yml reset.yml
}

default()
{
  tag=$1
  echo "default is called"
  ansible-playbook -K -i hosts.yml ${tag}.yml
}

test()
{
  machine=`cat ./.netrc | grep -e '^machine' | awk '{ print $2 }'`
  login=`cat ./.netrc | grep -e '^login' | awk '{ print $2 }'`
  echo "check account '$login' on https://${machine}:9200"
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


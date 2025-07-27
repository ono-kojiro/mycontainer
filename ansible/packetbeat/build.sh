#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

es_netrc="../elasticsearch/.netrc"
  
api_key_name="packetbeat"

rolename="packetbeat_writer"
username="packetbeat_internal"

machine=`cat ${es_netrc} | grep -e '^machine' | awk '{ print $2 }'`
es_url="https://${machine}:9200"


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

createkey()
{
  deletekey

  tmpfile=`mktemp`
  sh ../elasticsearch/api_key.sh create -n ${api_key_name} > $tmpfile
  api_key=`cat $tmpfile | jq -r '.api_key'`
  api_key_id=`cat $tmpfile | jq -r '.id'`
  #api_key_name=`cat $tmpfile | jq -r '.name'`

  cat $tmpfile

  mkdir -p host_vars/packetbeat/
  cat - << EOF > host_vars/packetbeat/api_key.yml
---
api_key_id:   ${api_key_id}
api_key_name: ${api_key_name}
api_key:      ${api_key}
EOF

  rm -f $tmpfile
}

deletekey()
{
  sh ../elasticsearch/api_key.sh delete -n ${api_key_name}
}

roleadd()
{
  role="packetbeat_setup"
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/role/$role" --data @- << EOS
{
  "cluster": [ "monitor", "manage_ilm" ],
  "indices": [
    {
      "names": [ "packetbeat-*" ],
      "privileges": [ "manage" ]
    }
  ],
  "description" : "Custom role for setting up index templates and other dependencies"
}
EOS

  role="packetbeat_writer"
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/role/$role" --data @- << EOS
{
  "cluster": [ "monitor", "read_ilm" ],
  "indices": [
    {
      "names": [ "packetbeat-*" ],
      "privileges": [ "create_doc" ]
    },
    {
      "names": [ "packetbeat-*" ],
      "privileges": [ "auto_configure" ]
    }
  ],
  "description" : "Custom role for publishing events collected by Packetbeat"
}
EOS

}

roledel()
{
  roles="packetbeat_setup packetbeat_writer"

  for rolename in ${roles}; do
    curl -k --netrc-file $es_netrc \
      -H 'Content-Type: application/json' \
      -XDELETE "$es_url/_security/role/$rolename?pretty"
  done
}

useradd()
{
  password=`pwgen 12 1`
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "${password}",
  "roles" : [ "$rolename", "kibana_admin" ],
  "full_name" : "Internal Packetbeat User"
}
EOS

  {
    echo "machine ${machine}"
	echo "login ${username}"
	echo "password ${password}"
  } > ./.netrc
}

userdel()
{
  username="packetbeat_internal"
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
  ansible-playbook -K -i hosts.yml site.yml
}

reset()
{
  ansible-playbook -K -i hosts.yml reset.yml
}

default()
{
  tag=$1
  echo "tag: ${tag}"
  ansible-playbook -K -i hosts.yml -t ${tag} site.yml
}

test()
{
  machine=`cat ./.netrc | grep -e '^machine' | awk '{ print $2 }'`
  login=`cat ./.netrc | grep -e '^login' | awk '{ print $2 }'`
  echo "check account '$login' on https://${machine}:9200"
  curl -k --netrc-file ./.netrc https://${machine}:9200
}

start()
{
  sudo systemctl start packetbeat
}

restart()
{
  sudo systemctl restart packetbeat
}

debug()
{
  sudo /usr/share/packetbeat/bin/packetbeat -c /etc/packetbeat/packetbeat.yml

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


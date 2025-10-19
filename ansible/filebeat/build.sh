#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

es_netrc="../elasticsearch/.netrc"
  
api_key_name="filebeat"

rolename="filebeat_writer"
username="filebeat_internal"

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

  createkey   create api key
  deletekey   delete api key

  roleadd     create writer role
  useradd     create internal user

  userdel     delete internal user
  roledel     delete writer role

  reset       reset password of internal user

  destroy     remove package
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
  sh ../elasticsearch/api_key.sh create -n ${api_key_name} \
      -r filebeat_writer > $tmpfile
  api_key=`cat $tmpfile | jq -r '.api_key'`
  api_key_id=`cat $tmpfile | jq -r '.id'`

  cat $tmpfile

  mkdir -p host_vars/filebeat/
  cat - << EOF > host_vars/filebeat/api_key.yml
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
  role="filebeat_setup"
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/role/$role?pretty" --data @- << EOS
{
  "cluster": [ "monitor", "manage_ilm" ],
  "indices": [
    {
      "names": [ "filebeat-*" ],
      "privileges": [ "manage" ]
    }
  ],
  "description" : "Custom role for setting up index templates and other dependencies"
}
EOS

  role="filebeat_writer"
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_url/_security/role/$role?pretty" --data @- << EOS
{
  "cluster": [ "monitor", "read_ilm" ],
  "indices": [
    {
      "names": [ "filebeat-*" ],
      "privileges": [ "create_doc" ]
    },
    {
      "names": [ "filebeat-*" ],
      "privileges": [ "auto_configure" ]
    }
  ],
  "description" : "Custom role for publishing events collected by filebeat"
}
EOS

}

roledel()
{
  roles="filebeat_setup filebeat_writer"

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
  "full_name" : "Internal Filebeat User"
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
  username="filebeat_internal"
  curl -k --netrc-file $es_netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_url/_security/user/$username?pretty"
}

reset()
{
  ansible-playbook $flags -i hosts.yml reset.yml
}

destroy()
{
  ansible-playbook $flags -i hosts.yml destroy.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
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
  sudo systemctl start filebeat
}

restart()
{
  sudo systemctl restart filebeat
}

debug()
{
  sudo /usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml
  :
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


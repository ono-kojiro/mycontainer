#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

host="192.168.0.178"
user="dummy"
ldap_uri="ldap://192.168.0.98"
ldap_suffix="dc=example,dc=com"

mkdir -p group_vars

cat - << EOF > group_vars/all.yml
---
host: "$host"
user: "$user"
ldap_uri:     "$ldap_uri"
ldap_suffix:  "$ldap_suffix"
EOF

help()
{
  usage
}

usage()
{
  echo "usage : $0 [options] target1 target2 ..."
cat - << EOS
  target:
    all
EOS
}

all()
{
  ansible-playbook -i hosts site.yml
}

key()
{
  ssh-keygen -t ed25519 -N '' -f id_ed25519 -C kali
}

ssh()
{
  command ssh -i id_ed25519 ${user}@${host}
}

default()
{
  tag=$1
  ansible-playbook -K -i hosts --tag $tag site.yml
}

debug()
{
  ansible-playbook -K -i hosts debug.yml
}

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
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    default $arg
  fi
done


#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ldap_confs="/etc/ldap/ldap.conf /etc/openldap/ldap.conf"

for ldap_conf in $ldap_confs; do
  if [ ! -e $ldap_conf ]; then
    continue
  fi
  uri=`cat $ldap_conf | sed -e 's/#.*//g' | grep URI | awk '{ print $2 }'`
  if [ -z "$uri" ]; then
    echo "ERROR: no URI in $ldap_conf"
    exit 1
  else
	break
  fi
done

basedn=`cat $ldap_conf | sed -e 's/#.*//g' | grep BASE | awk '{ print $2 }'`
if [ -z "$uri" ]; then
  echo "ERROR: no BASE in $ldap_conf"
  exit 1
fi

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] publickey.pub
EOS

}

add_public_key()
{
  pubkeyfile=$1
  pubkey=`cat $pubkeyfile | head -n 1`

  uiddn=`ldapsearch -x -LLL uid=$USER dn | awk '{ print $2 }'`
  binddn=$uiddn
  
  cat - << EOF > input.ldif
dn: $uiddn
changetype: modify
add: sshPublicKey
sshPublicKey: $pubkey
EOF

  cat input.ldif

  cmd="ldapadd -H $uri -D $binddn -f input.ldif -W"
  echo $cmd
  $cmd
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
  add_public_key $arg
done

#for arg in $args; do
#  num=`LANG=C type $arg | grep 'function' | wc -l`
#  if [ $num -ne 0 ]; then
#    $arg
#  else
#    echo "ERROR : $arg is not shell function"
#    exit 1
#  fi
#done


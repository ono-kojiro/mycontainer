#!/bin/sh

ldap_conf="/etc/ldap/ldap.conf"

ldap_base=`cat $ldap_conf | grep -e '^BASE ' | awk '{ print $2 }'`
ldap_uri=`cat $ldap_conf | grep -e '^URI ' | awk '{ print $2 }'`

username="$USER"

firstname=""
lastname=""
commonname=""

pubkey_file=""

usage()
{
  cat - << EOF
usage: $0 [OPTIONS]

  -g, --givenName, -f, --firstname     First Name (ex. Satoshi)
  -s, --sn, -l, --lastname             Last Name (ex. Nakamoto)
  -u, --username                       Username (ex. satoshi)
  -c, --commonname                     CommonName (ex. Satoshi Nakamoto)
  -p, --public-key                     Public Key File (ex. id_ed25519.pub)

EOF
}


add_public_key()
{
  echo "add_public_key"
  if [ -z "$pubkey_file" ]; then
    echo "ERROR: no pubkey_file"
    exit 1
  fi

  cat $pubkey_file | \
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$line" ]; then
      continue
    fi
    echo "LINE: $line"
    key="$line"
    binddn="uid=$username,ou=Users,$ldap_base"

    tmpfile=`mktemp -p /tmp -t tmp.XXXXXXXXXX` || exit
    echo "DEBUG: tmpfile is $tmpfile"

    cat - << EOF > $tmpfile
dn: uid=$username,ou=Users,$ldap_base
changetype: modify
add: sshPublicKey
sshPublicKey: $key
EOF

    cat $tmpfile
    cmd="ldapmodify -x -H $ldap_uri -D $binddn -W"
    cat $tmpfile | $cmd

    rm -f $tmpfile
  done
}

args=""
while [ "$#" -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    -g | --givenName )
      shift
      firstname="$1"
      ;;
    -s | --sn )
      shift
      lastname="$1"
      ;;
    -f | --firstname )
      shift
      firstname="$1"
      ;;
    -l | --lastname )
      shift
      lastname="$1"
      ;;
    -u | --username )
      shift
      username="$1"
      ;;
    -c | --commonname )
      shift
      commonname="$1"
      ;;
    -p | --public-key )
      shift
      pubkey_file="$1"
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

if [ -z "$commonname" ]; then
  if [ ! -z "$firstname" ] && [ ! -z "$lastname" ]; then
    commonname="$firstname $lastname"
  fi
fi

#for target in $args; do
#  num=`LANG=C type $target 2>&1 | grep 'function' | wc -l`
#  if [ "$num" -ne 0 ]; then
#    $target
#  else
#    default $target
#  fi
#done

add_public_key
exit 0


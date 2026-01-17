#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""
debug=0

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
    -d )
      debug=1
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
  
suffix=`cat /etc/ldap/ldap.conf | grep BASE | awk '{ print $2 }'`
uri=`cat /etc/ldap/ldap.conf | grep URI | awk '{ print $2 }'`

if [ "$debug" -ne 0 ]; then
  echo suffix is $suffix
  echo uri is $uri
fi

dn="uid=$USER,ou=Users,$suffix"

for pubfile in $args; do
  publickey=`cat $pubfile`

  if [ "$debug" -ne 0 ]; then
    echo $publickey
  fi

  ldapmodify -x -H $uri -D uid=$USER,ou=Users,$suffix -W << EOF
dn: $dn
changetype: modify
add: sshPublicKey
sshPublicKey: $publickey
EOF

done


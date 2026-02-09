#!/bin/sh

ldap_conf="/etc/ldap/ldap.conf"

ldap_base=`cat $ldap_conf | grep -e '^BASE ' | awk '{ print $2 }'`
ldap_uri=`cat $ldap_conf | grep -e '^URI ' | awk '{ print $2 }'`

username="$USER"

firstname=""
lastname=""
commonname=""

help()
{
  cat - << EOF
usage: $0 subcmd [OPTIONS]
EOF
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

tmpfile=`mktemp -p /tmp -t tmp.XXXXXXXXXX` || exit

echo $tmpfile
count=0

cat - << EOF >> $tmpfile
dn: uid=$username,ou=Users,$ldap_base
changetype: modify
EOF

if [ ! -z "$firstname" ]; then
  if [ "$count" -ne 0 ]; then
    echo '-' >> $tmpfile
  fi

  cat - << EOF >> $tmpfile
replace: givenName
givenName: $firstname
EOF

  count=`expr $count + 1`
fi

if [ ! -z "$lastname" ]; then
  if [ "$count" -ne 0 ]; then
    echo '-' >> $tmpfile
  fi

  cat - << EOF >> $tmpfile
replace: sn
sn: $lastname
EOF

  count=`expr $count + 1`
fi

if [ ! -z "$commonname" ]; then
  if [ "$count" -ne 0 ]; then
    echo '-' >> $tmpfile
  fi

  cat - << EOF >> $tmpfile
replace: cn
cn: $commonname
EOF

  count=`expr $count + 1`
fi


echo "========================="
cat $tmpfile
echo "========================="

binddn="uid=$username,ou=Users,$ldap_base"

cmd="ldapmodify -x -H $ldap_uri -D $binddn -W"
cat $tmpfile | $cmd

rm -f -- "$tmpfile"

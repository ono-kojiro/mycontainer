#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

es_host="https://192.168.0.98:9200"

netrc="${top_dir}/.netrc"

ret=0

help() {
  cat - << EOS
usage :
  $0 create -u <username> [-p <password>]
  $0 passwd -u <username> [-p <password>]
  $0 check  -u <username> [-p <password>]
  $0 delete -u <username>
  $0 list
EOS
}

usage()
{
  help
}

clean()
{
  :
}

# REST APIs
# https://www.elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html

create()
{
  if [ -z "$username" ]; then
    echo "no username option"
    ret=`expr $ret + 1`
  fi
  
  if [ $ret -ne 0 ]; then
    usage
    exit $ret
  fi


  echo "create user $username"
  if [ -z "$password" ]; then
    echo -n "enter user password: "
    stty_orig=$(stty -g)
    stty -echo
    read password
    stty $stty_orig
  fi

  tty -s && echo

  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_host/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "$password",
  "enabled" : true,
  "roles" : [ "superuser", "kibana_admin" ],
  "full_name" : "$fullname",
  "email" : "$email",
  "metadata" : {
    "intelligence" : 7
  }
}
EOS

}

create_logstash()
{
  username="logstash_internal"

  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_host/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "logstash",
  "roles" : [ "logstash_writer"],
  "full_name" : "Internal Logstash User"
}
EOS

}

delete()
{
  if [ -z "$username" ]; then
    echo "no username option"
    ret=`expr $ret + 1`
  fi

  if [ $ret -ne 0 ]; then
    usage
    exit $ret
  fi

  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_host/_security/user/$username?pretty"
}

passwd()
{
  if [ -z "$username" ]; then
    echo "no username option"
    ret=`expr $ret + 1`
  fi

  if [ $ret -ne 0 ]; then
    usage
    exit $ret
  fi

  if [ -z "$password" ]; then
    echo -n "enter user password (first): "
    stty_orig=$(stty -g)
    stty -echo
    read password1
    stty $stty_orig
    tty -s && echo
  
    echo -n "enter user password (second): "
    stty_orig=$(stty -g)
    stty -echo
    read password2
    stty $stty_orig
    tty -s && echo

    if [ "$password1" != "$password2" ]; then
      echo "ERROR: password not match"
      ret=`expr $ret + 1`
    fi
    password=$password1
  fi

  if [ $ret -ne 0 ]; then
    usage
    exit $ret
  fi

  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_host/_security/user/$username/_password?pretty" --data @- << EOS
{
  "password" : "$password"
}
EOS
}


check()
{
  if [ -z "$username" ]; then
    echo "no username option"
    ret=`expr $ret + 1`
  fi

  if [ $ret -ne 0 ]; then
    usage
    exit $ret
  fi

  if [ -z "$password" ]; then
    echo -n "enter user password (first): "
    stty_orig=$(stty -g)
    stty -echo
    read password1
    stty $stty_orig
    tty -s && echo
  
    echo -n "enter user password (second): "
    stty_orig=$(stty -g)
    stty -echo
    read password2
    stty $stty_orig
    tty -s && echo

    if [ "$password1" != "$password2" ]; then
      echo "ERROR: password not match"
      ret=`expr $ret + 1`
    fi
    password=$password1
  fi

  if [ $ret -ne 0 ]; then
    usage
    exit $ret
  fi

  curl -k \
    -H 'Content-Type: application/json' \
    -u "$username:$password" \
    -XGET "$es_host"
}

version() {
  curl -k --netrc-file $netrc $es_host?pretty
}

list()
{
  curl --silent -k --netrc-file $netrc "$es_host/_security/user?pretty"
}


indices() {
  curl -k --netrc-file $netrc "$es_host/_cat/indices?v"
}

tables() {
  indices
}

all()
{
  create
  password
  version
  delete
}

args=""

username=""
password=""
fullname=""
email=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h )
      usage;;
    -v )
      verbose=1;;
    -l )
      shift
      logfile=$1;;
    -u | --username )
      shift
      username=$1;;
    -p | --password )
      shift
      password=$1;;
    *)
      args="$args $1"
  esac

  shift
done

#if [ -z "$password" ]; then
#  echo "no password option"
#  ret=`expr $ret + 1`
#fi

if [ $ret -ne 0 ]; then
  usage
  exit $ret
fi

#if [ $# -eq 0 ]; then
#  create
#  exit
#fi

if [ -z "$args" ]; then
  usage
  exit 1
fi



for arg in $args ; do
  num=`LANG=C type $arg | grep 'function' | wc -l`

  if [ $num -ne 0 ]; then
    $arg
  else
    echo "no such function, $arg"
    exit 1
  fi
done


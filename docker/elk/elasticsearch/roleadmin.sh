#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

es_host="https://192.168.0.98:9200"

netrc="${top_dir}/netrc"

ret=0

help() {
  cat - << EOS
usage :
  $0 create -u <username> [-p <password>]
  $0 passwd -u <username> [-p <password>]
  $0 check  -u <username> [-p <password>]
  $0 delete -u <username>
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

update()
{
  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XPOST "$es_host/_security/role/logstash_writer?pretty" --data @- << EOS
{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"], 
  "indices": [
    {
      "names": [ "logstash-*", "cpu_load-*", "nw_load-*", "filebeat-*" ],
      "privileges": ["write","create","create_index","manage","manage_ilm", "auto_configure", "all" ]  
    }
  ]
}
EOS

}

delete()
{
  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XDELETE "$es_host/_security/role/logstash_writer?pretty"
}

list()
{
  curl -k --netrc-file $netrc \
    -H 'Content-Type: application/json' \
    -XGET "$es_host/_security/role?pretty"
}


all()
{
  add
  delete
}

args=""

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

#if [ -z "$args" ]; then
#  usage
#  exit 1
#fi

for arg in $args ; do
  num=`LANG=C type $arg | grep 'function' | wc -l`

  if [ $num -ne 0 ]; then
    $arg
  else
    echo "no such function, $arg"
    exit 1
  fi
done


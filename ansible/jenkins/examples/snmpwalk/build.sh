#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

args=""
flags=""

help()
{
  cat - << EOF
usage: $0 TARGET [TARGET...]
EOF

}

prepare()
{
  echo "Prepare"
}

build()
{
  umask 0002
  echo "Build"
  #tm=`date --iso-8601 seconds`
  tm=`LANG=C date "+%Y%m%d-%H%M%S"`
  remote="192.168.1.252"
  logfile="/home/agent/snmpwalk/${remote}-${tm}.log"
  mkdir -p /home/agent/snmpwalk
  snmpwalk $remote > $logfile 2>/dev/null
}

result()
{
  echo "Result"
}


while [ "$#" -ne 0 ]; do
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
  target=`echo $arg | tr '-' '_'`
  num=`LANG=C type $target 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $target
  else
    default $target
  fi
done



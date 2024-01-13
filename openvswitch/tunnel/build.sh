#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd $top_dir

segments="60 70 80"

remote_ip="192.168.0.98"

all()
{
  :
}

list()
{
  brs=`sudo ovs-vsctl list-br`
  for br in $brs; do
    echo "Bridge: $br"
    ports=`sudo ovs-vsctl list-ports $br`
    for port in $ports; do
      echo "  $port"
    done
  done
}

add()
{
  for segment in $segments; do
    br="ovsbr${segment}"
    gre="gre${segment}"

    cmd="sudo ovs-vsctl add-port $br $gre"
    cmd="$cmd -- set interface $gre type=gre option:remote_ip=$remote_ip"
    echo $cmd
    $cmd
  done
}

del()
{
  sudo ovs-vsctl del-port ovsbr60 gre0
}



usage()
{
  cat - << EOF
usage : $0 all
EOF
}

while [ $# -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  all
fi

for target in "$@"; do
  LANG=C type "$target" | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done


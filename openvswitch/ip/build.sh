#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd $top_dir

items="60 70 80"

devname="ovsbr60"
addr_mask="192.168.60.254/24"

all()
{
  for item in $items; do
    devname="ovsbr$item"
    addr_mask="192.168.$item.254/24"
    got=`ip addr show $devname | grep 'inet ' | awk '{ print $2 }'`
    if [ "x$got" = "x$addr_mask" ]; then
      echo "SKIP: $devname, $addr_mask"
      continue
    fi
    echo "set addr: $devname, $addr_mask"

    sudo -- sh -c " \
      ip addr add $addr_mask dev $devname; \
      ip link set $devname down; \
      ip link set $devname up; \
    "
  done
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


#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd $top_dir

devname="ovsbr60"
addr_mask="192.168.60.254/24"

all()
{
  sudo ip addr add $addr_mask dev $devname
  sudo ip link set $devname down
  sudo ip link set $devname up
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


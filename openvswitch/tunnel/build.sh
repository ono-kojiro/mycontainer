#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd $top_dir

all()
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


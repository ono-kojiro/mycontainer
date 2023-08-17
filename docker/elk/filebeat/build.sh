#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

LS_VER=8.6.2
LS_ARCH=amd64

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    destroy
EOS
}

all()
{
  help
}

fetch()
{
  PKGVER=8.6.2
  ES_ARCH=amd64
  wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.6.2-amd64.deb
}

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h )
      usage
	  ;;
    -v )
      verbose=1
	  ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

for target in $args ; do
  LANG=C type $target | grep function > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done


#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="focal"

image="${release}"
container="${release}"

help()
{
  usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    debootstrap
EOS
}

all()
{
  help
}

prepare()
{
  sudo apt-get -y install debootstrap
}

debootstrap()
{
  url="http://jp.archive.ubuntu.com/ubuntu/"

  cat - << EOF | sudo -- sh -s
{
  cd /var/lib/machines
  pwd
  /usr/sbin/debootstrap --include=systemd-container \
    --components="main,universe" \
    $release $container $url
}
EOF
}

status()
{
  #machinectl list-images
  sudo systemctl status systemd-nspawn@focal
}

run()
{
  sudo -- sh -c 'cd /var/lib/machines; systemd-nspawn -D focal'
}

edit()
{
  sudo systemctl edit systemd-nspawn@focal
}


start()
{
  sudo systemctl start systemd-nspawn@focal
}

restart()
{
  sudo systemctl restart systemd-nspawn@focal
}


attach()
{
  echo "press Ctrl+P, Ctrl+Q to detacch from the container"
  docker attach $container
}

bash()
{
  docker exec -it $container /bin/bash
}

stop()
{
  docker compose stop
}

down()
{
  docker compose down
}


ip()
{
  docker inspect \
    --format '{{.Name}} {{ .NetworkSettings.IPAddress }}' \
	$(docker ps -q)
}

if [ "$#" = "0" ]; then
  usage
  exit 1
fi

args=""

while [ "$#" != "0" ]; do
  case "$1" in
    h)
      usage
	  ;;
    v)
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
  if [ "$?" = "0" ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done


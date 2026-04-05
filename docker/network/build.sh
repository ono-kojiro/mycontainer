#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

./gen_env.py > ./env
./gen_compose.py > docker-compose.yml

. ./env

flags="--env-file ./env"

help()
{
  usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    fetch
    create
    start
    stop
    ip
EOS
}

all()
{
  help
}

create()
{
  docker compose $flags up --no-start
}

start()
{
  docker compose $flags start
}

attach1()
{
  docker exec -it ${CLIENT1_NAME} /bin/bash
}

attach2()
{
  docker exec -it ${CLIENT2_NAME} /bin/bash
}

ssh1()
{
  command ssh -p ${CLIENT1_LPORT} localhost
}

ssh2()
{
  command ssh -p ${CLIENT2_LPORT} localhost
}

ssh3()
{
  command ssh -p ${CLIENT3_LPORT} localhost
}


stop()
{
  docker compose $flags stop
}

down()
{
  docker compose $flags down
}

ls_nw()
{
  docker network ls
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ "$#" -ne 0 ]; do
  case "$1" in
    h)
      usage
	  ;;
    v)
      verbose=1
	  ;;
    -*)
      flags="$flags $1"
      ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

echo "DEBUG: $args"

for target in $args ; do
  LANG=C type $target 2>&1 | grep function >/dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done


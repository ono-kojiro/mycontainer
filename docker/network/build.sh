#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

./gen_env.py config.yml > ./env

./gen_compose.py config.yml > docker-compose.yml
. ./env

flags="--env-file ./env"
driver="macvlan"

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

attach3()
{
  docker exec -it ${CLIENT3_NAME} /bin/bash
}

attach4()
{
  docker exec -it ${CLIENT4_NAME} /bin/bash
}

attach5()
{
  docker exec -it ${CLIENT5_NAME} /bin/bash
}

attach6()
{
  docker exec -it ${CLIENT6_NAME} /bin/bash
}

attach7()
{
  docker exec -it ${CLIENT7_NAME} /bin/bash
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

ssh4()
{
  command ssh -p ${CLIENT5_LPORT} localhost
}

ssh5()
{
  command ssh -p ${CLIENT5_LPORT} localhost
}

ssh6()
{
  command ssh -p ${CLIENT6_LPORT} localhost
}

ssh7()
{
  command ssh -p ${CLIENT7_LPORT} localhost
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


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

create_bridges()
{
  docker network create -d macvlan \
    --subnet=${CLIENT1_SUBNET} \
    --gateway ${CLIENT1_GATEWAY} \
    --opt parent=${CLIENT1_PARENT} \
    ${CLIENT1_PARENT}_macvlan

  docker network create -d macvlan \
    --subnet=${CLIENT2_SUBNET} \
    --gateway ${CLIENT2_GATEWAY} \
    --opt parent=${CLIENT2_PARENT} \
    ${CLIENT2_PARENT}_macvlan

  docker network create -d macvlan \
    --subnet=${CLIENT3_SUBNET} \
    --gateway ${CLIENT3_GATEWAY} \
    --opt parent=${CLIENT3_PARENT} \
    ${CLIENT3_PARENT}_macvlan

  docker network create -d macvlan \
    --subnet=${CLIENT4_SUBNET} \
    --gateway ${CLIENT4_GATEWAY} \
    --opt parent=${CLIENT4_PARENT} \
    ${CLIENT4_PARENT}_macvlan

  docker network create -d macvlan \
    --subnet=${CLIENT5_SUBNET} \
    --gateway ${CLIENT5_GATEWAY} \
    --opt parent=${CLIENT5_PARENT} \
    ${CLIENT5_PARENT}_macvlan

  docker network create -d macvlan \
    --subnet=${CLIENT6_SUBNET} \
    --gateway ${CLIENT6_GATEWAY} \
    --opt parent=${CLIENT6_PARENT} \
    ${CLIENT6_PARENT}_macvlan

  docker network create -d macvlan \
    --subnet=${CLIENT7_SUBNET} \
    --gateway ${CLIENT7_GATEWAY} \
    --opt parent=${CLIENT7_PARENT} \
    ${CLIENT7_PARENT}_macvlan

}

create()
{
  create_bridges
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


remove_bridges()
{
  bridges=""
  bridges="$bridges ${CLIENT1_PARENT}_macvlan"
  bridges="$bridges ${CLIENT2_PARENT}_macvlan"
  bridges="$bridges ${CLIENT3_PARENT}_macvlan"
  bridges="$bridges ${CLIENT4_PARENT}_macvlan"
  bridges="$bridges ${CLIENT5_PARENT}_macvlan"
  bridges="$bridges ${CLIENT6_PARENT}_macvlan"
  bridges="$bridges ${CLIENT7_PARENT}_macvlan"

  for bridge in $bridges; do
    docker network rm $bridge
  done
}

down()
{
  docker compose $flags down
  remove_bridges
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


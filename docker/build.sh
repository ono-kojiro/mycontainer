#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=iperf3

build()
{
  docker build --tag $name .
}

run()
{
  docker run -it --rm --name $name $name /bin/sh
}

create_net()
{
  docker network create \
    --driver macvlan \
    --subnet=192.168.7.0/24 \
    --gateway=192.168.7.2 \
    -o parent=macvlan0 \
    mymacvlan
}

ls_net()
{
  docker network ls
}

remove_net()
{
  docker network remove mymacvlan
}

rm_net()
{
  remove_net
}


net()
{
  docker run --rm -it \
    --network mymacvlan \
    --ip=192.168.7.9 \
    --name $name $name /bin/sh
}


clean()
{
  id=`docker images | grep $name | awk '{ print $3 }'`
  docker rmi --force $id
}



for target in "$@" ; do
  LANG=C type $target | grep function > /dev/null 2>&1
  res=$?
  if [ "x$res" = "x0" ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done


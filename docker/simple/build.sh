#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

remote="yocto"

image="myimage"
container="mycontainer"
network="mynetwork"

help()
{
  echo "usage : $0 <target>"
  echo ""
  echo "  image      create image"
  echo "  network    create network"
  echo "  container  create container"
  echo "  start      start container"
  echo "  attach     attach container"
  echo "  stop       stop container"
  echo ""
  echo "  rm         remove container"
  echo "  rmi        remove image"
  echo "  rmn        remove network"
  echo ""
  echo "  clean    stop/remove container, remove image"
}

image()
{
  cat - << 'EOS' | ssh -y $remote bash -s -- $image
{
  image=$1

  {
    echo '#!/bin/sh'
    echo 'while true ; do'
    echo '  /bin/bash'
    echo 'done'
  } > startup.sh

  {
    echo 'FROM scratch'
    echo 'COPY tmp /tmp/'
    echo 'ADD startup.sh /'
    echo 'ENTRYPOINT ["/startup.sh"]'
  } > Dockerfile

  rm -rf tmp
  mkdir -p tmp
  docker build --tag $image .
  #rm -rf tmp

  #rm -f Dockerfile
  #rm -f startup.sh
}
EOS

}

network()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $network
  {
    network=$1

    docker network create \
      -d macvlan \
      --subnet=192.168.7.0/24 \
      --gateway=192.168.7.1 \
      -o parent=macvlan0 \
      $network
  }
EOS

}

rmn()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $network
  {
    network=$1
    
    docker network rm $network
  }
EOS

}

container()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $image $container $network
  {
    image=$1
    container=$2
    network=$3

    docker create \
      -it \
      --name $container \
      -v /bin:/bin \
      -v /lib:/lib \
      -v /usr/bin:/usr/bin \
      -v /usr/lib:/usr/lib \
      -v /usr/lib64:/usr/lib64 \
      -v /sbin:/sbin \
      --network $network \
      $image \
      /bin/bash
  }
EOS

}

rmi()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $image
  {
    image=$1
    docker rmi $image
  }
EOS

}

start()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $container
  {
    container=$1
  
    docker start $container
  }
EOS

}

attach()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $container
  {
    container=$1

    echo "Press Ctrl+P, Ctrl+Q to detach container."
    docker attach $container
  }
EOS

}

stop()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $container
  {
    container=$1
    docker stop $container
  }
EOS

}

rm()
{
  cat - << 'EOS' | ssh -y $remote sh -s -- $container
  {
    container=$1
    docker rm $container
  }
EOS

}

prepare()
{
  image
  network
  container
}

clean()
{
  stop
  rm 
  rmi
  rmn
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



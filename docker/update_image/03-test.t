#!/bin/sh

echo "1..4"

cat - << 'EOS' | ssh -y yocto sh -s
{
  echo 1 > version.txt

  {
     echo "FROM scratch"
     echo "ADD version.txt /"
     echo 'CMD ["/bin/bash"]'
  } > Dockerfile

  docker build --tag myimage .
  res=$?
  if [ "$res" = "0" ]; then
    echo "ok - docker build"
  else
    echo "Bail out! docker build failed"
  fi

  rm -f version.txt Dockerfile

  docker tag myimage 192.168.7.1:5000/myimage
  res=$?
  if [ "$res" = "0" ]; then
    echo "ok - docker tag passed"
  else
    echo "Bail out! docker tag failed"
  fi
    
    docker create -it \
      --name mycontainer \
      -v /bin:/bin \
      -v /lib:/lib \
      192.168.7.1:5000/myimage
    docker start mycontainer
    docker exec mycontainer /bin/bash -c '
      dd if=/dev/urandom of=/16MB.bin bs=1024k count=16
    '
    docker commit mycontainer 192.168.7.1:5000/myimage:latest

  echo ""
  echo "docker push"
  echo ""
  docker push 192.168.7.1:5000/myimage
  res=$?
  if [ "$res" = "0" ]; then
    echo "ok - docker push passed"
  else
    echo "Bail out! docker push failed"
  fi
  
  for ver in `seq 1 2`; do
    ids=`docker ps -a -q`
    if [ ! -z "$ids" ]; then
      echo "remove all containers"
      docker rm  -f $ids > /dev/null 2>&1
    fi

    ids=`docker images -q`
    if [ ! -z "$ids" ]; then
      echo "remove all images"
      docker rmi -f $ids > /dev/null 2>&1
    fi

    echo ""
    echo "docker pull"
    echo ""
    docker pull 192.168.7.1:5000/myimage

    echo ""
    echo "docker create"
    echo ""
    docker create -it \
      --name mycontainer \
      -v /bin:/bin \
      -v /lib:/lib \
      192.168.7.1:5000/myimage

    echo ""
    echo "docker start"
    echo ""
    docker start mycontainer
    got=`docker exec mycontainer /bin/bash -c 'cat /version.txt'`
    if [ "$got" = "$ver" ]; then
      echo "version number $got, ok"
    else
      echo "version number $got, not ok"
    fi

    echo ""
    echo "docker exec and increment version"
    echo ""
    next_ver=`expr $ver + 1`
    docker exec mycontainer /bin/bash -c "echo $next_ver > /version.txt"

    echo ""
    echo "docker commit"
    echo ""
    docker commit mycontainer 192.168.7.1:5000/myimage:latest
    
    echo ""
    echo "docker push"
    echo ""
    docker push 192.168.7.1:5000/myimage:latest
  done
}

EOS


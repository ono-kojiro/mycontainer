#!/bin/sh

scp create_image.sh yocto:/home/root/

cat - << 'EOS' | ssh -y yocto sh -s
{
    sh create_image.sh -n myimage
    docker tag myimage 192.168.7.1:5000/myimage
    docker push 192.168.7.1:5000/myimage
    
    docker rm  -f $(docker ps -a -q)
    docker rmi -f $(docker images -q)


    echo ""
    echo "docker push finished."
    echo ""
    echo ""
    for ver in `seq 1 2`; do
      echo ""
      echo "docker pull"
      echo ""
      echo ""
      docker pull 192.168.7.1:5000/myimage

      echo ""
      echo "docker create"
      echo ""
      echo ""
      docker create -it --name mycontainer \
        -v /bin:/bin \
        -v /lib:/lib \
        192.168.7.1:5000/myimage

      echo ""
      echo "docker start"
      echo ""
      echo ""
      docker start mycontainer
      got=`docker exec mycontainer /bin/bash -c 'cat /version.txt'`
      if [ "$got" = "$ver" ]; then
        echo "version number $got, ok"
      else
        echo "version number $got, not ok"
      fi

      next_ver=`expr $ver + 1`
      docker exec mycontainer /bin/bash -c "echo $next_ver > /version.txt"

      docker commit mycontainer 192.168.7.1:5000/myimage:latest
      docker push 192.168.7.1:5000/myimage:latest
      
      docker rm  -f $(docker ps -a -q)
      docker rmi -f $(docker images -q)
    done
}

EOS


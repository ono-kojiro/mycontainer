#!/bin/sh

args=""

name=""

# MB
size=4

usage()
{
  echo "usage: $0 [options] target1 target2 ..."
}

while [ "$#" != "0" ]; do
  case $1 in
    -h | --help)
      usage
      exit 1
      ;;
    -v | --version)
      usage
      exit 1
      ;;
    -n | --name)
      shift
      image=$1
      ;;
    -s | --size)
      shift
      size=$1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

init()
{
  if [ -z "$image" ]; then
    echo ERROR : no name option
    exit 1
  fi

  rm -rf tmp; mkdir -p tmp

  datafile=data-${size}MB.bin
  dd if=/dev/urandom of=$datafile bs=1024k count=${size}

  echo 1 > version.txt

  cat - << "EOS" > Dockerfile
FROM scratch
ADD version.txt /
CMD ["/bin/bash"]
EOS

  docker build --tag $image .

  rm -f Dockerfile
  rm -rf tmp
  rm -f $datafile
  rm -f version.txt

  docker save $image | gzip > $image.tar.gz
}

#if [ -z "$args" ]; then
#  usage
#  exit 1
#fi


init

#for arg in $args; do
#  LANG=C type $arg | grep 'function' > /dev/null 2>&1
#  res=$?
#  if [ "$res" = "0" ]; then
#    $arg
#  else
#    echo ERROR : $arg not a function
#  fi
#done



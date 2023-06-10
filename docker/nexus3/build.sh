#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="nexus3"

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    create
    start
    stop
    down
EOS
}

all()
{
  help
}

prepare()
{
  if [ ! -e /var/lib/nexus ]; then
    sudo mkdir -p /var/lib/nexus
  fi

  sudo chown -R 200:200 /var/lib/nexus
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

attach()
{
  #docker attach $name
  docker exec -it --user root $name /bin/bash
}

debug()
{
  mkdir -p log
  rm -f log/*
  docker cp $name:/nexus-data/log/jvm.log log/
  docker cp $name:/nexus-data/log/karaf.log log/
  docker cp $name:/nexus-data/log/nexus.log log/
  docker cp $name:/nexus-data/log/nexus_cluster.log log/
  docker cp $name:/nexus-data/log/request.log log/

}

get()
{
  echo get jetty-https.xml
  docker cp $name:/opt/sonatype/nexus/etc/jetty/jetty-https.xml .
  echo get nexus.properties
  docker cp $name:/nexus-data/etc/nexus.properties .
}

patch()
{
  command patch -p0 < change_keystore_path.patch
  command patch -p0 < change_property.patch
}

clean()
{
  rm -f jetty-https.xml.orig jetty-https.xml
  rm -f nexus.properties.orig nexus.properties
}

tmp()
{
  keytool \
    -genkeypair \
    -keystore keystore.jks \
    -storepass changeit \
    -keypass changeit \
    -alias jetty \
    -keyalg RSA \
    -keysize 2048 \
    -validity 5000 \
    -dname "CN=*.example.com, OU=Unspecified, O=Unspecified, L=Unspecified, ST=Unspecified, C=JP" \
    -ext "SAN=DNS:host.example.com,IP:192.168.0.98" \
    -ext "BC=ca:true"
}

put()
{
  cmd="docker cp keystore.jks $name:/nexus-data/keystores/"
  echo $cmd
  $cmd
  
  cmd="docker exec --user root $name chown 200:200 /nexus-data/keystores/keystore.jks"
  echo $cmd
  $cmd

  cmd="docker exec $name mkdir -p /nexus-data/etc/jetty/"
  echo $cmd
  $cmd

  cmd="docker cp jetty-https.xml $name:/nexus-data/etc/jetty/"
  echo $cmd
  $cmd
  
  cmd="docker exec --user root $name chown 200:200 /nexus-data/etc/jetty/jetty-https.xml"
  echo $cmd
  $cmd

  cmd="docker cp nexus.properties $name:/nexus-data/etc/"
  echo $cmd
  $cmd
  
  cmd="docker exec --user root $name chown 200:200 /nexus-data/etc/nexus.properties"
  echo $cmd
  $cmd
}

log()
{
  mkdir -p log
  docker cp $name:/nexus-data/log/nexus.log log/
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

destroy()
{
  sudo rm -rf /var/lib/nexus
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


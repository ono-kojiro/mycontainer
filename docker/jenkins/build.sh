#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="jenkins"
  
JAVA_OPTS="-Djavax.net.ssl.trustStore=$top_dir/cacerts"
  
JENKINS_URL="https://192.168.0.98:18443/jenkins"

username=$USER

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
    init
    build
    create
    start
    stop
    ip
EOS
}

all()
{
  destroy
  init

  create
  start
}

fetch()
{
  docker compose pull
}

pull()
{
  fetch
}

build()
{
  docker build -t ${name} .
}

create()
{
  docker compose up --no-start
}

status()
{
  #ip addr show docker0
  #docker network inspect bridge
  docker ps -a | grep ${name}
}

start()
{
  docker compose start
}

attach()
{
  #docker attach ${name}
  docker exec -it --user root ${name} /bin/bash
}

ssh()
{
  command ssh -p 22040 localhost
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

init()
{
  docker cp jenkins.jks ${name}:/var/jenkins_home/
}

destroy()
{
  sudo rm -rf /home/jenkins/
}

cacert()
{
  docker cp ./myca.pem ${name}:/var/jenkins_home/

  # call keytool with absolute cacert path
  docker exec --user root ${name} \
    keytool -import -trustcacerts \
    -keystore /opt/java/openjdk/lib/security/cacerts \
    -storepass changeit \
    -noprompt \
    -alias myca \
    -file /var/jenkins_home/myca.pem
}

show_ca()
{
  docker exec --user root ${name} \
    keytool -list \
    -keystore /opt/java/openjdk/lib/security/cacerts \
    -storepass changeit \
    | grep myca
}

cacerts()
{
  docker cp jenkins:/opt/java/openjdk/lib/security/cacerts .
}

cli_help()
{
  java $JAVA_OPTS -jar jenkins-cli.jar -s $JENKINS_URL help
}

get_cli()
{
  curl -k -O $JENKINS_URL/jnlpJars/jenkins-cli.jar
}

plugin()
{
  plugins="LDAP matrix-auth sshd"
  plugins="$plugins ssh-slaves"          # ssh-slaves
  plugins="$plugins workflow-aggregator" # pipeline

  if [ -z "$password" ]; then
    echo -n "enter user password: "
    stty_orig=$(stty -g)
    stty -echo
    read password
    stty $stty_orig
  fi

  tty -s && echo

  for name in $plugins; do
    echo "install plugin: $name"
    java $JAVA_OPTS -jar jenkins-cli.jar -s $JENKINS_URL \
      -auth $username:$password \
      install-plugin $name
  done
}

restart_jenkins()
{
  java $JAVA_OPTS \
    -jar jenkins-cli.jar -s $JENKINS_URL \
    -auth $username:$password \
    restart
}

test_ssh()
{
  java -jar jenkins-cli.jar -s $JENKINS_URL \
    -ssh -user jenkins
}

restart()
{
  #java -jar jenkins-cli.jar -s $JENKINS_URL \
  #  -auth jenkins:jenkins \
  #  restart
  stop
  start
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


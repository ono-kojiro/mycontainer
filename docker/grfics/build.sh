#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

target:
  deploy
EOS

}

all()
{
  deploy
}

prepare()
{
  docker exec -it kali /bin/bash -c 'apt -y update'
  docker exec -it kali /bin/bash -c 'apt -y install openssh-server'
  docker exec -it kali /bin/bash -c 'service ssh start'
  
  #docker exec -it kali /bin/bash -c 'ifconfig eth0' | tee kali-ip.log
  #ip=`cat kali-ip.log | grep ' inet ' | awk '{ print $2 }'`

  docker exec -i kali /bin/bash -c 'bash -s' << EOF
ifconfig eth0 > /tmp/ifconfig-eth0.log
cat /tmp/ifconfig-eth0.log
EOF

  docker cp kali:/tmp/ifconfig-eth0.log .
  addr=`cat ifconfig-eth0.log | grep ' inet ' | awk '{ print $2 }'`
  mkdir -p host_vars
  {
    echo "---"
    echo "ansible_host: $addr"
    echo "ansible_user: kali"
    echo "ansible_become: true"
  } > host_vars/kali.yml

  rm -f ifconfig-eth0.log

  docker exec -i kali /bin/bash -c 'bash -s' << EOF
mkdir -p /home/kali/.ssh/
chmod 700 /home/kali/.ssh
EOF

  docker cp $HOME/.ssh/id_ed25519.pub kali:/home/kali/.ssh/authorized_keys
  
  docker exec -i kali /bin/bash -c 'bash -s' << EOF
chown -R kali:kali /home/kali/.ssh
EOF

}

hosts()
{
  if [ -e "host_vars/kali.yml" ]; then
    ansible-inventory -i inventory.yml --list --yaml > hosts.yml
  fi
}

deploy()
{
   ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t $tag site.yml
}

hosts

args=""
while [ $# -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
	-* )
	  flags="$flags $1"
	  ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for arg in $args; do
  num=`LANG=C type $arg | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done


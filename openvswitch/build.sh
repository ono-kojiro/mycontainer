#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="ovs-sw0"

num_port="8"

prefix="192.168.20"
mask="24"
ipv4_gateway="${prefix}.1"
ipv4_dns="${prefix}.1"

help()
{
    usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    add
    del
EOS
}

all()
{
  help
}

prepare()
{
  sudo dnf -y install NetworkManager-ovs
}

add_bridge()
{
  echo "add_bridge"
  sudo nmcli con add type ovs-bridge \
    conn.interface $name con-name $name
}

delete_bridge()
{
  sudo nmcli con del $name
}

add_port()
{
  echo "add_port"
  sudo -- sh -s << EOF
  i=0
  while [ "\$i" -lt $num_port ]; do
    nmcli con add type ovs-port \
      conn.interface ovs-port\${i} \
      master $name \
      con-name ovs-port\${i} \
      ovs-port.tag 2
    i=\`expr \$i + 1\`
  done
EOF
}

add_mng_port()
{
  sudo -- sh -s << EOF
nmcli con add type ovs-port \
  conn.interface ovs-mng-port \
  master $name \
  con-name ovs-mng-port \
  ovs-port.tag 2
EOF
  
}

delete_mng_port()
{
  sudo -- sh -s << EOF
nmcli con del ovs-mng-port
EOF
  
}


add_mng_if()
{
  sudo -- sh -s << EOF
nmcli con add type ovs-interface slave-type ovs-port \
  conn.interface ovs-mng-if \
  connection.id ovs-mng-if \
  master ovs-mng-port

nmcli con mod ovs-mng-if \
  ipv4.method manual \
  ipv4.address 192.168.20.254/24 \
  ipv4.dns     192.168.20.1 \
  ipv4.gateway 192.168.20.1 \
  ipv6.method disabled

nmcli con up ovs-mng-if
EOF
  
}

add_docker_if()
{
  sudo -- sh -s << EOF
nmcli con add \
  type ovs-interface \
  slave-type ovs-port \
  conn.interface ovs-if0 \
  connection.id ovs-if0 \
  master ovs-port0

nmcli con mod ovs-if0 ipv4.method disabled
nmcli con mod ovs-if0 ipv6.method disabled
EOF
}

debug()
{
  cat - << EOF | sudo sh -s
nmcli con mod br0 master ovs-port0 slave-type ovs-port
EOF
  
}

add_docker_br()
{
  cat - << EOF | sudo sh -s
nmcli con add type bridge ifname ovs-br0 con-name ovs-br0
nmcli con mod ovs-br0 master ovs-port0 slave-type ovs-port
EOF

}

delete_docker_br()
{
  cat - << EOF | sudo sh -s
nmcli con del ovs-br0
EOF
}

delete_docker_if()
{
  sudo -- sh -s << EOF
nmcli con del ovs-if0
EOF
}

delete_mng_if()
{
  sudo -- sh -s << EOF
nmcli con del ovs-mng-if
EOF

}

delete_port()
{
  sudo -- sh -s << EOF
  i=0
  while [ "\$i" -lt $num_port ]; do
    nmcli con del ovs-port\${i}
    i=\`expr \$i + 1\`
  done
EOF
}

show()
{
  sudo ovs-vsctl show
}

list()
{
  show
}

add()
{
  add_bridge
  add_port
  add_mng_port
  add_mng_if
  #add_docker_if
  add_docker_br
}

delete()
{
  delete_docker_br
  #delete_docker_if
  delete_mng_if
  delete_mng_port
  delete_port
  delete_bridge
}

del()
{
  delete
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h)
      usage
      ;;
    -v)
      verbose=1
      ;;
    *)
      args="$args $1"
      ;;
  esac
  shift
done

for target in $args ; do
  LANG=C type $target | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
    exit 1
  fi
done


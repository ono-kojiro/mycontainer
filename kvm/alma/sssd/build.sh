#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

addr="192.168.0.178"

seckey="id_ed25519"
inventory="hosts"
playbook="site.yml"

ansible_opts=""
ansible_opts="$ansible_opts -i ${inventory}"

usage()
{
  cat - << EOF
usage : $0 target1 target2 ...

target
  key

  deploy
EOF
}

help()
{
  usage
}

prepare()
{
  :
}

key()
{
  ssh-keygen -t ed25519 -N '' -f $seckey -C almalinux9
}

gen_hosts()
{
  ansible-inventory -i inventory --list --yaml > hosts
}

deploy()
{
  ansible-playbook -i hosts site.yml
}

connect()
{
  command ssh root@${addr}
}

ssh()
{
  command ssh root@${addr} -i $seckey
}

sftp()
{
  command sftp -i $seckey root@${addr}
}

_default()
{
  tag=$1
  cmd="ansible-playbook ${ansible_opts} -t ${tag} ${playbook}"
  echo $cmd
  $cmd
}

all()
{
  usage
}

gen_hosts

while [ $# -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  all
fi

for target in "$@"; do
  LANG=C type "$target" | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    #echo "ERROR : $target is not a shell function"
    #exit 1
    _default ${target}
  fi
done


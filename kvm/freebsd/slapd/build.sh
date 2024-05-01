#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

inventory="hosts"
playbook="site.yml"

ansible_opts=""
ansible_opts="$ansible_opts -i ${inventory}"

usage()
{
  cat - << EOF
usage : $0 target1 target2 ...

target
  all
  usage
EOF
}

help()
{
  usage
}

all()
{
  usage
}

hosts()
{
  ansible-inventory -i template.yml --list --yaml > hosts.yml
}

default()
{
  tag=$1
  ansible-playbook ${ansible_opts} -i hosts.yml -t ${tag} site.yml
}


hosts

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
    -p | --playbook)
      shift
      playbook=$1
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
  LANG=C type "$target" 2>&1 | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    default $target
  fi
done


#!/bin/sh

remote=192.168.7.2

usage()
{
  echo "$0"
}

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
	  usage
	  exit 1
	  ;;
	*)
	  break
	  ;;
  esac

  shift
done

cat - << 'EOS' | ssh -y $remote sh -s
{
  lxc-ls -f
}

EOS


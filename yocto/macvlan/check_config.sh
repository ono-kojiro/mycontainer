#!/bin/sh

cat - << 'EOS' | ssh -y yocto sh -s
{
  zcat /proc/config.gz | grep MACVLAN
}
EOS


#!/bin/sh

remote="192.168.7.2"

(
  cat - << 'EOS' | ssh -y $remote sh -s
  lxc-attach -n busybox -- iperf3 -s -1 > iperf3_s.log 2>&1
EOS
) & (
  sleep 3
  cat - << 'EOS' | ssh -y $remote sh -s
  {
    lxc-attach -n sshd -- iperf3 -c 192.168.7.5 > iperf3_c.log 2>&1
  }
EOS
  
)

cat - << 'EOS' | ssh -y $remote sh -s
{
  cat iperf3_s.log
  cat iperf3_c.log
}
EOS




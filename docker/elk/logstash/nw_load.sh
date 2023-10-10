#!/bin/sh

n=3600

while [ $n -ne 0 ]; do
  #2023-10-10 21:59:52+09:00
  ts=`date --rfc-3339=seconds`

# need tcpdump
timeout 3 tcpdump -w output.pcap -i eth0 > /dev/null 2>&1

# need tshark
capinfos output.pcap | grep 'Data bit rate: ' | tee output.log

#Data bit rate:       24 kbps
val=`cat output.log | awk '{ print $4 }' | sed 's|,||g'`
unit=`cat output.log | awk '{ print $5 }'`

case "$unit" in
  "bits/s" )
    unit="bps"
    ;;
  "kbps" )
    val=`echo $val \* 1000.0 | bc -l`
    unit="bps"
    ;;
  "Mbps" )
    val=`echo $val \* 1000.0 \* 1000.0 | bc -l`
    unit="bps"
    ;;
  * )
    ;;
esac

filename=`echo $ts | sed 's/[-:]//g' | sed 's/ /-/g' | head -c 15`

{
  echo "Timestamp,NW"
  #echo \"$ts\",\"$val $unit\"
  echo $ts,$val
} > $filename.csv

  n=`expr $n - 1`
done


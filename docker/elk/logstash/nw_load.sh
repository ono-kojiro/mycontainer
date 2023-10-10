#!/bin/sh

#2023-10-10 21:59:52+09:00
ts=`date --rfc-3339=seconds`

# need tcpdump
sudo timeout 3 tcpdump -w output.pcap -i wlan0 > /dev/null 2>&1

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
  * )
    ;;
esac

filename=`echo $ts | sed 's/[-:]//g' | sed 's/ /-/g' | head -c 15`

{
  echo "Timestamp,Bitrate"
  #echo \"$ts\",\"$val $unit\"
  echo $ts,$val
} > $filename.csv



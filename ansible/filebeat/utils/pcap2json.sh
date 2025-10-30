#!/bin/sh

usage()
{
  cat - << EOF
usage: $0 -i infile.pcap -o output.json
EOF
}

infile=""
outfile=""
auto_output=0

args=""
while [ "$#" -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    #-i | --infile)
    #  shift
    #  infile="$1"
    #  ;;
    -o | --outfile)
      shift
      outfile="$1"
      ;;
    -a | --auto-output)
      auto_output=1
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

ret=0

#if [ -z "$infile" ]; then
#  echo "ERROR: no infile option"
#  ret=`expr $ret + 1`
#fi

if [ "$auto_output" -ne 0 ] && [ ! -z "$outfile" ]; then
  echo "ERROR: outfile/auto-output options are exclusive"
  ret=`expr $ret + 1`
fi

if [ "$auto_output" -eq 0 ] && [ -z "$outfile" ]; then
  echo "ERROR: no outfile/auto-output options"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  usage
  exit $ret
fi

for infile in $args; do
  echo $infile | grep -i -e '.pcap.xz$' 1>/dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    precmd="xz -d -k -c"
  else
    precmd="cat"
  fi

  if [ "$auto_output" -ne 0 ]; then
    outfile=`echo $infile | sed 's/\.pcap\.xz$/.json/'`
    echo "INFO: outfile is $outfile"
  fi

  $precmd $infile | \
        editcap -d - - | \
        tshark -r - -T ek | \
        grep -v -e '^{"index":' > $outfile
done


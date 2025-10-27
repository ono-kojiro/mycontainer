#!/bin/sh

usage()
{
  cat - << EOF
usage: $0 -i infile.pcap -o output.json
EOF
}

infile=""
outfile=""

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
    -i | --infile)
      shift
      infile="$1"
      ;;
    -o | --outfile)
      shift
      outfile="$1"
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

if [ -z "$infile" ]; then
  echo "ERROR: no infile option"
  ret=`expr $ret + 1`
fi

if [ -z "$outfile" ]; then
  echo "ERROR: no outfile option"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  usage
  exit $ret
fi

echo $infile | grep -i -e '.pcap.xz$' 1>/dev/null 2>&1

if [ "$?" -eq 0 ]; then
  precmd="xz -d -k -c"
else
  precmd="cat"
fi

$precmd $infile | \
        editcap -d - - | \
        tshark -r - -T ek | \
        grep -v -e '^{"index":' > $outfile


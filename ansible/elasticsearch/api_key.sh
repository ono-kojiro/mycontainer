#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

netrc="./.netrc"

machine=`cat ${netrc} | grep -e '^machine' | awk '{ print $2 }'`
base_url="https://${machine}:9200"

name=""

usage()
{
  cat - << EOF
usage : $0 [TARGET...]

TARGET:
  create
EOF

}

create()
{
  if [ -z "$name" ]; then
    echo "ERROR: no name option"
	exit 1
  fi

  cat - << EOF > template.json
{
  "name": "myname",
  "expiration": "1d", 
  "metadata": {
    "application": "myapplication",
    "environment": {
       "level": 1,
       "trusted": true,
       "tags": ["dev", "staging"]
    }
  }
}
EOF

  cat template.json | sed -e "s/myname/${name}/" > data.json

  {		
    curl \
      -k \
     --silent \
      --netrc-file ${netrc} \
      -H 'Content-Type: application/x-ndjson' \
      -X POST ${base_url}/_security/api_key?pretty \
	  -d @data.json
  } | tee output.json

  rm -f template.json
}

list()
{
  curl \
    -k \
    --silent \
    --netrc-file ${netrc} \
    -H 'Content-Type: application/x-ndjson' \
    -X GET ${base_url}/_security/api_key?pretty
}

delete()
{
  if [ -z "$name" ]; then
    echo "ERROR: no name option"
	exit 1
  fi
  
  cat - << EOF > data.json
{
  "name": "${name}"
}
EOF

  curl \
    -k \
   --silent \
    --netrc-file ${netrc} \
    -H 'Content-Type: application/x-ndjson' \
    -X DELETE ${base_url}/_security/api_key?pretty -d @data.json
}

test()
{
  id=`jq -r '.id' output.json`
  api_key=`jq -r '.api_key' output.json`

  echo ""

  echo "id : $id"
  echo "api_key : $api_key"

  str="$id:$api_key"
  echo "input is $str"

  api_key=`echo -n "$id:$api_key" | base64`

  echo "base64 : $api_key"

  curl \
    -H "Authorization: ApiKey $api_key" \
    https://192.168.0.98:9200/
}

args=""
while [ $# -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
	  ;;
	-n | --name )
	  shift
	  name="$1"
      ;;
    * )
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  usage
fi

for arg in $args; do
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done



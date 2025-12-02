#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
#cd $top_dir

netrc="${top_dir}/.netrc"

machine=`cat ${netrc} | grep -e '^machine' | awk '{ print $2 }'`
base_url="https://${machine}:9200"

name=""
role=""

usage()
{
  cat - << EOF
usage : $0 [TARGET...]

TARGET:
  create
  list
  delete
EOF

}

create()
{
  ret=0

  if [ -z "$name" ]; then
    echo "ERROR: no name option"
    ret=`expr $ret + 1`
  fi
  
  if [ -z "$role" ]; then
    echo "ERROR: no role option"
    ret=`expr $ret + 1`
  fi

  if [ "$ret" -ne 0 ]; then
    exit $ret
  fi

  cat - << EOF > template.json
{
  "name": "myname",
  "role_descriptors": {
    "${role}" : {
      "cluster": ["all"],
      "indices": [
        {
          "names": ["*"],
          "privileges": ["all"]
        }
      ]
    },
    "custom_role": {
      "cluster": [ "manage_security" ]
    }
  },
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
  }

  rm -f template.json
  rm -f data.json
}

list()
{
  curl \
    -k \
    --silent \
    --netrc-file ${netrc} \
    -H 'Content-Type: application/x-ndjson' \
    -X GET ${base_url}/_security/api_key?pretty | \
  jq

  #jq '.api_keys.[] | select(.invalidated == false) | { id: .id, name: .name }'
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

  rm -f data.json
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
	-r | --role )
	  shift
	  role="$1"
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



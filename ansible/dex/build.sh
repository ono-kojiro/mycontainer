#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

if [ -f "hosts.yml" ]; then
  issuer_path='.all.children.servers.hosts.localhost.issuer'
  issuer_url=`cat hosts.yml | yq -r "$issuer_path"`
fi

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

  target:
    deply
    reset
EOS

}

all()
{
  deploy
}

clean()
{
  ansible-playbook -i hosts.yml clean.yml
}

hosts()
{
  ansible-inventory -i inventory.yml --list --yaml > hosts.yml
}

install()
{
  ansible-playbook $flags -i hosts.yml -t install site.yml
}

deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
}

keys()
{
  cmd="curl -k -s ${issuer_url}/keys"
  echo "CMD: $cmd"
  $cmd  | jq .
}

device_code()
{
   curl -s -k -X POST ${issuer_url}/device/code \
     -d "client_id=myclient" \
     -d "scope=openid email profile groups offline_access" \
   | jq . | tee device_code.json
}

device()
{
  device_code
}

auth()
{
   verification_uri_complete=`cat device_code.json \
     | jq -r ".verification_uri_complete"`
   lynx ${verification_uri_complete}
}

refresh_token()
{
  code=`cat device_code.json | jq -r ".device_code"`
  client_id="myclient"

  grant_type="urn:ietf:params:oauth:grant-type:device_code"
  curl -k -s -X POST ${issuer_url}/token \
          -d "grant_type=$grant_type" \
          -d "device_code=$code" \
          -d "client_id=$client_id" | jq . | tee refresh_token.json
}

refresh()
{
  refresh_token
}

access_token()
{
  ref=`cat refresh_token.json | jq -r ".refresh_token"`

  curl -k -s \
    -X POST ${issuer_url}/token \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$ref" \
    -d "client_id=myclient" | jq . | tee access_token.json
}

access()
{
  access_token
}


hosts

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
    -* )
      flags="$flags $1"
      ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for target in $args; do
  target=`echo $target | tr '-' '_'`
  num=`LANG=C type $target 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $target
  else
    #echo "ERROR : $target is not shell function"
    #exit 1
    default $target
  fi
done


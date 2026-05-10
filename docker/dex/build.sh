#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

if [ -e "./.env" ]; then
  . ./.env
fi

dex_crt="${DEX_CRT}"
dex_key="${DEX_KEY}"
dex_config="${DEX_CONFIG}"

set -a
. ./.env
envsubst < ${DEX_CONFIG_TEMPLATE} > ${DEX_CONFIG}
set +a

ret="0"

if [ ! -e "$dex_crt" ]; then
  echo "ERROR: no dex_crt variable"
  ret=`expr $ret + 1`
fi

if [ ! -e "$dex_key" ]; then
  echo "ERROR: no dex_key variable"
  ret=`expr $ret + 1`
fi

if [ ! -e "$dex_config" ]; then
  echo "ERROR: no $dex_config"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  exit 1
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    create            create container

    start             start container
    stop              stop container
    down              remove container
    destroy           remove container and volume

    device_code / device       get device code
    auth                       authorize using lynx
    refresh_token / refresh    get refresh token
    access_token  / access     get access token
EOF
}

help()
{
  usage
}

attach()
{
  docker exec -it -u root ${CONTAINER_NAME} /bin/sh
}

log()
{
  docker compose logs -f ${CONTAINER_NAME}
}

create()
{
  docker compose up --no-start

  config
}

start()
{
  docker compose start
}

stop()
{
  docker compose stop
}

restart()
{
  stop
  start
}

down()
{
  docker compose down
}

config()
{
  echo -n "INFO: create dummy container ... "
  docker container create --name dummy \
     -v dex-config:/etc/dex \
     -v dex-data:/var/lib/dex \
     alpine >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: create /etc/dex/certs directory ... "
  docker run --rm -i -u root \
    -v dex-config:/etc/dex \
    -v dex-data:/var/lib/dex \
    alpine /bin/sh -s << EOF
  {
    mkdir -p /etc/dex/certs
    chown 1001:1001 /etc/dex/certs
  }
EOF

  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: upload dex.crt ... "
  docker cp -q dex.crt dummy:/etc/dex/certs/
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: upload dex.key ... "
  docker cp -q dex.key dummy:/etc/dex/certs/
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  echo -n "INFO: upload config-ldap.yaml ... "
  docker cp -q config-ldap.yaml dummy:/etc/dex/
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  echo -n "INFO: change permission ... "
  docker run --rm -i -u root \
    -v dex-config:/etc/dex \
    -v dex-data:/var/lib/dex \
    alpine /bin/sh -s << EOF
  {
    chown -R 1001:1001 /etc/dex/certs
    chmod 755 /etc/dex/certs/dex.crt
    chmod 700 /etc/dex/certs/dex.key
    touch /var/lib/dex/dex.db
    chmod 777 /var/lib/dex/
    chown 1001:1001 /var/lib/dex/dex.db
  }
EOF
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  
  echo -n "INFO: check permission ... "
  docker run --rm -i -u root \
    -v dex-config:/etc/dex \
    -v dex-data:/var/lib/dex \
    alpine /bin/sh -s << EOF > permission.log
  {
    ls -lR /etc/dex/
    ls -lR /var/lib/dex/
  }
EOF
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: remove dummy container ... "
  docker rm dummy >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
}

update_config()
{
  #docker cp dex.crt dex:/etc/dex/certs/
  #docker cp dex.key dex:/etc/dex/certs/
  docker cp config-ldap.yaml dex:/etc/dex/
}

status()
{
  docker ps -a | grep ${CONTAINER_NAME}
}

destroy()
{
  down
  docker volume rm ${CONTAINER_NAME}-config
  docker volume rm ${CONTAINER_NAME}-data
}

check_keys()
{
  echo "INFO : get https://${DEX_IP}:${DEX_PORT}/dex/keys"
  curl -s -k https://${DEX_IP}:${DEX_PORT}/dex/keys | jq . | tee keys.json
  echo "INFO : output is keys.json"
}

device_code()
{
   curl -s -k -X POST https://${DEX_IP}:${DEX_PORT}/dex/device/code \
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
  curl -k -s -X POST https://${DEX_IP}:${DEX_PORT}/dex/token \
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
    -X POST https://${DEX_IP}:${DEX_PORT}/dex/token \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$ref" \
    -d "client_id=myclient" | jq . | tee access_token.json
}

access()
{
  access_token
}

args=""

while [ "$#" -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  usage
fi

for target in $args; do
  target=`echo $target | tr '-' '_'`
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done


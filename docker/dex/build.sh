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

    code
    refresh
    access
EOF
}

help()
{
  usage
}

attach()
{
  docker exec -it ${CONTAINER_NAME} /bin/sh
}

log()
{
  docker compose logs -f ${CONTAINER_NAME}
}

create()
{
  docker compose up --no-start
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
  echo "INFO: create dummy container"
  docker container create --name dummy \
     -v dex-config:/etc/dex \
     -v dex-data:/var/lib/dex \
     alpine

  echo "INFO: create /etc/dex/certs directory"
  docker run --rm -i -u root \
    -v dex-config:/etc/dex \
    -v dex-data:/var/lib/dex \
    alpine /bin/sh -s << EOF
  {
    mkdir -p /etc/dex/certs
    chown 1001:1001 /etc/dex/certs
  }
EOF

  echo "INFO: upload certs and config"
  docker cp dex.crt dummy:/etc/dex/certs/
  docker cp dex.key dummy:/etc/dex/certs/
  docker cp config-ldap.yaml dummy:/etc/dex/
  
  echo "INFO: create /etc/dex/certs directory"
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
  
  echo "INFO: check permission"
  docker run --rm -i -u root \
    -v dex-config:/etc/dex \
    -v dex-data:/var/lib/dex \
    alpine /bin/sh -s << EOF
  {
    ls -lR /etc/dex/
    ls -lR /var/lib/dex/
  }
EOF

  echo "INFO: remove dummy container"
  docker rm dummy
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

keys()
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

code()
{
  device_code
}

refresh()
{
  code=`cat device_code.json | jq -r ".device_code"`
  client_id="myclient"

  grant_type="urn:ietf:params:oauth:grant-type:device_code"
  curl -k -s -X POST https://${DEX_IP}:${DEX_PORT}/dex/token \
          -d "grant_type=$grant_type" \
          -d "device_code=$code" \
          -d "client_id=$client_id" | jq . | tee refresh_token.json
}

access()
{
  ref=`cat refresh_token.json | jq -r ".refresh_token"`

  curl -k -s \
    -X POST https://${DEX_IP}:${DEX_PORT}/dex/token \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$ref" \
    -d "client_id=myclient" | jq . | tee access_token.json
}

test()
{
  access_token=`cat access_token.json | jq -r ".access_token"`
  id_token=`cat access_token.json | jq -r ".id_token"`

  token="$id_token"

  curl -s -k \
    -H "Authorization: Bearer $token" \
    https://192.168.1.72:6984/
  
  curl -s -k \
    -H "Authorization: Bearer $token" \
    https://192.168.1.72:6984/_session

}

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
      break
      ;;
  esac

  shift
done

if [ "$#" -eq 0 ]; then
  usage
fi

for target in "$@"; do
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done


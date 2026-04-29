#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=".env"

if [ -e "${ENVFILE}" ]; then
  . ./${ENVFILE}
fi
    
couchdb_user="${COUCHDB_USER}"
couchdb_password="${COUCHDB_PASSWORD}"

dex_https="192.168.1.72:5554"

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    create            create container

    config            configure

    start             start container
    
    stop              stop container
    down              remove container
    destroy           remove container and volume

  ---
  device_code         get device code
  auth                start lynx
  refresh_token       get refresh token
  access_token        get access_token
  test_token          test access token 
EOF
}

help()
{
  usage
}

attach()
{
  docker exec -it couchdb /bin/bash
}

dump_config()
{
  curl -s -k \
    -u ${couchdb_user}:${couchdb_password} https://${COUCHDB_IP_PORT}/_node/_local/_config \
  | jq .
}

keys2ini()
{
  echo "INFO : get https://${dex_https}/dex/keys"
  curl -s -k https://${dex_https}/dex/keys | jq . > keys.json
  echo "INFO : output is keys.json"
  
  python3 jwk2pem.py -o dex_public.pem keys.json

  kid=`cat keys.json | jq -r ".keys[$index].kid"`
  echo "kid: $kid"

  {
    echo "[jwt_keys]"
    echo -n "rsa:$kid = "
    cat dex_public.pem | \
      awk '
        NR>1{printf "\\n"}
        {printf "%s", $0}
      '
    echo ""
    
  } > config/couchdb/dex_keys.ini
  echo "INFO: write config/couchdb/dex_keys.ini"
}

log()
{
  docker compose logs -f couchdb
}

create()
{
  docker compose --env-file ${ENVFILE} up --no-start
  config
}

config()
{
  keys2ini

  echo "INFO: create dummy container"
  docker container create --name dummy \
     -v "couchdb-config:/opt/couchdb/etc/local.d" \
     -v "couchdb-certs:/opt/couchdb/etc/certs" \
     -v "couchdb-data:/opt/couchdb/data" \
     alpine

  echo "INFO: upload certs"
  docker cp config/ssl/couchdb.crt dummy:/opt/couchdb/etc/certs/
  docker cp config/ssl/couchdb.key dummy:/opt/couchdb/etc/certs/

  echo "INFO: upload config"
  docker cp config/ssl/ssl.ini      dummy:/opt/couchdb/etc/local.d/
  docker cp config/couchdb/jwt.ini      dummy:/opt/couchdb/etc/local.d/
  docker cp config/couchdb/dex_keys.ini dummy:/opt/couchdb/etc/local.d/
  
  echo "INFO: change permission"
  docker run --rm -i -u root \
    -v "couchdb-config:/opt/couchdb/etc/local.d" \
    -v "couchdb-certs:/opt/couchdb/etc/certs" \
    -v "couchdb-data:/opt/couchdb/data" \
    alpine /bin/sh -s << EOF
  {
    chown -R 1001:1001 /opt/couchdb/etc/certs
  }
EOF

  echo "INFO: check permission"
  docker run --rm -i -u root \
    -v "couchdb-config:/opt/couchdb/etc/local.d" \
    -v "couchdb-data:/opt/couchdb/data" \
    alpine /bin/sh -s << EOF
  {
    ls -lR /opt/couchdb/etc/local.d
  }
EOF

  echo "INFO: remove dummy container"
  docker rm dummy
}

start()
{
  docker compose --env-file ${ENVFILE} start
}

status()
{
  docker ps -a | grep couchdb
}

stop()
{
  docker compose --env-file ${ENVFILE} stop
}

restart()
{
  stop
  start
}

down()
{
  docker compose --env-file ${ENVFILE} down
}

destroy()
{
  down
  docker volume rm couchdb-config
  docker volume rm couchdb-certs
  docker volume rm couchdb-data
}

test_http()
{
  curl -s -k \
    -u ${couchdb_user}:${couchdb_password} http://${COUCHDB_HTTP}/
}

test_https()
{
  curl -s -k \
    -u ${couchdb_user}:${couchdb_password} https://${COUCHDB_HTTPS}/
}

welcome()
{
  curl -s -k -v \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} https://${COUCHDB_HTTPS}/
}

device_code()
{
   curl -s -k -X POST https://${dex_https}/dex/device/code \
     -d "client_id=myclient" \
     -d "scope=openid email profile groups offline_access" \
   | jq . | tee device_code.json
}

auth()
{
   verification_uri_complete=`cat device_code.json | jq -r ".verification_uri_complete"`
   lynx ${verification_uri_complete}
}

refresh_token()
{
  code=`cat device_code.json | jq -r ".device_code"`
  client_id="myclient"
  
  grant_type="urn:ietf:params:oauth:grant-type:device_code"
  curl -k -s -X POST https://${dex_https}/dex/token \
          -d "grant_type=$grant_type" \
          -d "device_code=$code" \
          -d "client_id=$client_id" | jq . | tee refresh_token.json
}

access_token()
{
  ref=`cat refresh_token.json | jq -r ".refresh_token"`

  curl -k -s \
    -X POST https://${dex_https}/dex/token \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$ref" \
    -d "client_id=myclient" | jq . | tee access_token.json
}

test_token()
{
  test_access_token
}

test_access_token()
{
  access_token=`cat access_token.json | jq -r ".access_token"`

  curl -s -k \
    -H "Authorization: Bearer $access_token" \
    https://${COUCHDB_HTTPS}/_session
}

without_access_token()
{
  curl -s -k \
    https://${COUCHDB_HTTPS}/_session
}


all_dbs()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} https://${COUCHDB_HTTPS}/_all_dbs
}


all()
{
  keys
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
  all
fi

for target in "$@"; do
  target=`echo $target | tr '-' '_'`
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done


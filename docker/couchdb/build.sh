#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=".env"

pkgname="couchdb"
pkgver="3.5.1"

if [ -e "${ENVFILE}" ]; then
  . ./${ENVFILE}
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    create            create container
    start             start container
    
    ssl               enable ssl
    stop              stop container
    down              remove container
    destroy           remove container and volume

  ---
  public              update dex public key
  
  token               get access token using refresh token
  check               access to couchdb using access token  
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

check_health()
{
  cmd="curl -k -X GET https://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:6984/"
  #echo "DEBUG: $cmd"
  $cmd
}

check_config()
{
  url="https://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:6984"
  echo "DEBUG: check cttpd"
  curl -s -k $url/_node/_local/_config/chttpd | jq
  echo "DEBUG: check cttpd_auth"
  curl -s -k $url/_node/_local/_config/chttpd_auth | jq
  echo "DEBUG: check jwt_auth"
  curl -s -k $url/_node/_local/_config/jwt_auth | jq
  echo "DEBUG: check jwt_keys"
  cmd="curl -s -k $url/_node/_local/_config/jwt_keys"
  echo $cmd
  $cmd | jq .
}

get_access_token()
{
  jwt=`cat access_token.json | jq -r '.access_token'`
  echo $jwt
}

jwt()
{
  docker cp config/couchdb/jwt.ini couchdb:/opt/couchdb/etc/local.d/
  docker cp config/couchdb/jwt_keys.ini couchdb:/opt/couchdb/etc/local.d/
}

verify()
{
  echo "INFO : get https://192.168.1.72:5556/dex/keys"
  curl -s -k https://192.168.1.72:5556/dex/keys | jq . > keys.json
  echo "INFO : output is keys.json"
  #cat keys.json

  index="0"
  echo "INFO: key index $index"
  n=`cat keys.json | jq -r ".keys[$index].n"`
  echo $n
  e=`cat keys.json | jq -r ".keys[$index].e"`
  echo $e
  
  kid=`cat keys.json | jq -r ".keys[$index].kid"`
  echo "kid: $kid"
  sh jwks_to_pem.sh "$n" "$e" > dex_public.pem

}


pubkey()
{
  echo "INFO : get https://192.168.1.72:5556/dex/keys"
  curl -s -k https://192.168.1.72:5556/dex/keys | jq . > keys.json
  echo "INFO : output is keys.json"

  index="0"
  echo "INFO: key index $index"
  n=`cat keys.json | jq -r ".keys[$index].n"`
  echo $n
  e=`cat keys.json | jq -r ".keys[$index].e"`
  echo $e
  
  kid=`cat keys.json | jq -r ".keys[$index].kid"`
  echo "kid: $kid"
  sh jwks_to_pem.sh "$n" "$e" > dex_public.pem

  {
    echo "[jwt_keys]"
    echo -n "rsa:$kid = "
    cat dex_public.pem | \
      awk '
        NR>1{printf "\\n"}
        {printf "%s", $0}
      '
    echo ""
    
  } > config/couchdb/jwt_keys.ini
  echo "INFO: write config/couchdb/jwt_keys.ini"
      
  docker cp config/couchdb/jwt_keys.ini couchdb:/opt/couchdb/etc/local.d/
}

ssl()
{
  docker cp config/ssl/couchdb.crt couchdb:/tmp/
  docker cp config/ssl/couchdb.key couchdb:/tmp/
  docker cp config/ssl/ssl.ini couchdb:/opt/couchdb/etc/local.d/
  docker exec -i couchdb /bin/bash << EOF
{
  mkdir -p /opt/couchdb/etc/certs
  mv -f /tmp/couchdb.* /opt/couchdb/etc/certs/
  chown couchdb:couchdb /opt/couchdb/etc/certs/couchdb.*
  chmod 600 /opt/couchdb/etc/certs/couchdb.key
  chmod 644 /opt/couchdb/etc/local.d/ssl.ini
}
EOF

}

config()
{
  defaultconfig
  localconfig
}

defaultconfig()
{
  :
}

localconfig()
{
  docker cp local.ini couchdb:/opt/couchdb/etc/local.d/
}

unconfig()
{
  docker exec -i couchdb /bin/bash << EOF
{
  rm -f /opt/couchdb/etc/local.d/local.ini
}
EOF
}


log()
{
  docker compose logs -f couchdb
}

mod()
{
  docker cp couchdb:/opt/couchdb/etc/local.d/docker.ini .
}

postproc()
{
  copy_png
}

create()
{
  docker compose --env-file ${ENVFILE} up --no-start
}

start()
{
  docker compose --env-file ${ENVFILE} start
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
  docker volume rm couchdb-data
}

token()
{
  ref="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  curl -k -s \
  -X POST https://192.168.1.72:5556/dex/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=$ref" \
  -d "client_id=example-app" \
  -d "client_secret=ZXhhbXBsZS1hcHAtc2VjcmV0" \
  -o access_token.json
}

check()
{
  access_token=`cat access_token.json | jq -r '.access_token'`
  #echo "INFO: access_token is $access_token"

  #curl -s -v -k \
  #  -H "Authorization: Bearer $access_token" \
  #  https://192.168.1.72:6984/_session
  
  curl -s -k -v \
    -H "Authorization: Bearer $access_token" \
    https://192.168.1.72:6984/_session
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
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done


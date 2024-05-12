#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

pkgname="elasticsearch"
pkgver="8.13.4"
url=https://artifacts.elastic.co/downloads/$pkgname/$pkgname-$pkgver-amd64.deb

url_dl="https://artifacts.elastic.co/downloads"
es_url="$url_dl/elasticsearch/elasticsearch-$pkgver-amd64.deb"
kibana_url="$url_dl/kibana/kibana-$pkgver-amd64.deb"
ls_url="$url_dl/logstash/logstash-$pkgver-amd64.deb"
    
help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    elasticsearch
    reset

    update
    kibana

    test_simple, test_http, test_https
    down
    destroy
EOS
}

all()
{
  help
}

fetch()
{
  cd roles/elasticsearch/files
  filename=`basename $es_url`
  if [ ! -e "$filename" ]; then
    wget $es_url
  else
    echo "skip: $filename"
  fi
  cd $top_dir

  cd roles/kibana/files
  filename=`basename $kibana_url`
  if [ ! -e "$filename" ]; then
    wget $kibana_url
  else
    echo "skip: $filename"
  fi
  cd $top_dir
  
  cd roles/logstash/files
  filename=`basename $ls_url`
  if [ ! -e "$filename" ]; then
    wget $ls_url
  else
    echo "skip: $filename"
  fi
  cd $top_dir
}

hosts()
{
  ansible-inventory -i template.yml --list --yaml > hosts.yml
}

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

restart()
{
  stop
  start
}

test()
{
  test_es
  test_kibana
}

test_https()
{
   echo "test https"
   curl -k --netrc-file ./netrc \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/
}

test_es()
{
   curl \
     -k \
     --cacert ./myca.crt \
     --netrc-file ./netrc \
     -X GET \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/ 
}

test_kibana()
{
   curl \
     -k \
     --cacert ./myca.crt \
     --netrc-file ./kibana-netrc \
     -X GET \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/ 
}

user()
{
  es_host="192.168.0.98:9200"

  username=$USER
  fullname=`git config --get user.name`
  email=`git config --get user.mail`

  stty -echo
  printf "Password: "
  read PASSWORD
  stty echo
  printf "\n"

  password=$PASSWORD

  curl -k --netrc-file ./netrc \
    -H 'Content-Type: application/json' \
    -XPOST "https://$es_host/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "$password",
  "enabled" : true,
  "roles" : [ "superuser", "kibana_admin" ],
  "full_name" : "$fullname",
  "email" : "$email",
  "metadata" : {
    "intelligence" : 7
  }
}
EOS

}

create_logstash_user()
{
  es_host="192.168.0.98:9200"

  username="logstash"
  fullname="$username"
  password="logstash"

  curl -k --netrc-file ./netrc \
    -H 'Content-Type: application/json' \
    -XPOST "https://$es_host/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "$password",
  "enabled" : true,
  "roles" : [ "superuser" ],
  "full_name" : "$fullname",
  "metadata" : {
    "intelligence" : 7
  }
}
EOS

}


reset()
{
  ansible-playbook -K -i hosts.yml -t reset site.yml
}

update()
{
  pass=`cat kibana-netrc | grep -e '^password' | awk '{ print $2 }'`
  sed -i -e "s/^\(kibana_password\): .*/\1: $pass/" group_vars/all.yml
}


default()
{
  tag="$1"
  ansible-playbook -K -i hosts.yml -t $tag site.yml
}

hosts

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h )
      usage
	  ;;
    -v )
      verbose=1
	  ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

for target in $args ; do
  LANG=C type $target 2>&1 | grep function > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    default $target
    #echo "$target is not a shell function"
    #exit 1
  fi
done


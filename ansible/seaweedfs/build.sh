#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

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

deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
}

test_http()
{
  endpoint_url="http://localhost:8333"
  aws_opts="--endpoint-url $endpoint_url"
  
  run_test
}

test_https()
{
  . ./.env

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export PYTHONWARNINGS="ignore:Unverified HTTPS request"

  endpoint_url="https://localhost:8333"
  aws_opts="--endpoint-url $endpoint_url --no-verify-ssl"

  run_test
}

run_test()
{
  exp=`uuidgen`
  echo "INFO: exp is $exp"
  rm -f test.txt

  aws $aws_opts s3 rb s3://mybucket --force || true
  aws $aws_opts s3 mb s3://mybucket
  echo -n "$exp" > test.txt
  aws $aws_opts s3 cp test.txt s3://mybucket/test.txt

  rm -f test.txt

  aws $aws_opts s3 ls s3://mybucket
  aws $aws_opts s3 cp s3://mybucket/test.txt ./test.txt

  got=`cat test.txt`
  echo "INFO: got is $got"
  if [ "$exp" = "$got" ]; then
    echo "TEST: passed"
  else
    echo "TEST: failed"
  fi
}

orig_test_https()
{
  . ./.env

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export PYTHONWARNINGS="ignore:Unverified HTTPS request"

  endpoint_url="https://localhost:8333"
  aws_opts="--endpoint-url $endpoint_url --no-verify-ssl"

  aws $aws_opts s3 rb s3://mybucket --force || true
  aws $aws_opts s3 mb s3://mybucket
  date > hello.txt
  aws $aws_opts s3 cp hello.txt s3://mybucket/hello.txt
  aws $aws_opts s3 ls s3://mybucket
  aws $aws_opts s3 cp s3://mybucket/hello.txt ./hello_downloaded.txt
  cat hello_downloaded.txt
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


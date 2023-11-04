#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ca_name=MyLocalCA

output_dir="$top_dir"
cabase=`echo $ca_name | tr '[:upper:]' '[:lower:]'`
cacert="${output_dir}/${cabase}.pem"

database="$output_dir/db"
password=${password:-"secret"}
months_valid=120

extkeyusage="serverAuth"
certtype="sslServer"

help() {
  echo "usage : $0 <target>"
  cat - << EOS
  target
   init   init database and ca
   crt    create server.crt
   clean  remove database
EOS

}

prepare()
{
  sudo apt -y install libnss3-tools
}

clean() {
	echo clean database
	rm -rf ${database}
	rm -f ${cacert}
}

list() {
	certutil -L -d ${database}
}

db() {
  if [ "$show_help" != "0" ]; then
    echo "usage: $0 init"
    exit 1
  fi

  mkdir -p ${database}
  rm -f ${database}/*

  echo create database ${database}
  certutil -N -d ${database} --empty-password
}


ca() {
  if [ -z "$ca_name" ]; then
    echo "ERROR : no ca_name option"
    exit 1
  fi

  echo make a certificate, ${database}
  echo $password > password.txt
  dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
  echo "initialize CA, $database"

  mkdir -p ${database}

  printf 'y\n0\ny\n' | \
  certutil -S \
	-x \
	-d ${database} \
	-z noise.bin \
	-n "$ca_name" \
	-s "cn=${ca_name}" \
	-t "CT,C,C" \
	-m $RANDOM \
	-k rsa \
	-g 2048 \
	-Z SHA256 \
	-f password.txt \
	-v $months_valid \
	-2
}

save()
{ 
  echo export ${cacert}
  mkdir -p ${output_dir}
  certutil -L -d ${database} \
    -n "$ca_name" -a > ${cacert}
  
  rm -f password.txt noise.bin
}

all()
{
  db
  ca
  save
}

crt() {
  if [ "$show_help" != "0" ]; then
    echo "usage : $0 --output output.crt --input input.csr addr1 addr2 ..."
    exit 1
  fi

  ret=0
  if [ -z "$output" ]; then
    echo "ERROR : no output option"
    ret=`expr $ret + 1`
  fi
  
  if [ -z "$input" ]; then
    echo "ERROR : no input option"
    ret=`expr $ret + 1`
  fi

  #if [ $# -eq 0 ]; then
  #  echo "no server addresses"
  #  ret=`expr $ret + 1`
  #fi

  if [ $ret != 0 ]; then
    exit $ret
  fi
    
  server_addrs="$@"

  echo CA: create ${output}
  echo $password > password.txt

  extsan="dns:localhost"
  for addr in $server_addrs; do
    extsan="$extsan,ip:$addr"
  done

  # -C : create a new binary certificate file		
  #-x \
  cmd="certutil -C"
  cmd="$cmd -c $ca_name"
  cmd="$cmd -i ${input}"
  cmd="$cmd -a"
  cmd="$cmd -o ${output}"
  cmd="$cmd -f password.txt"
  cmd="$cmd --extSAN $extsan"
  cmd="$cmd -v 120"
  cmd="$cmd -d ${database}"
  cmd="$cmd --nsCertType $certtype"
  cmd="$cmd --extKeyUsage $extkeyusage"
  
  echo $cmd
  $cmd
  echo "generated ${output}"
  rm -f password.txt
}

vars()
{
  echo "ca_name      : ${ca_name}"
  echo "database     : ${database}"
  echo "cacert       : ${cacert}"
  echo "input        : ${input}"
  echo "output       : ${output}"
  echo "server_addr  : ${server_addr}"
}

clean()
{
  rm -f ${output_dir}/*.pem
}

destroy()
{
  rm -rf ${output_dir}
}

if [ "$#" -eq 0 ]; then
  show_help
  exit 1
fi

subcmd=$1
shift
	
num=`LANG=C type $subcmd | grep 'function' | wc -l`
if [ "$num" -eq 0 ]; then
  echo \"$subcmd\" is not a function.
  exit 2
fi

args=""
show_help=0

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
      show_help=1
      ;;
    -c | --ca_name)
      shift
      ca_name=$1
      ;;
    -i | --input)
      shift
      input=$1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    -e | --extkeyusage)
      shift
      extkeyusage=$1
      ;;
    -t | --certtype)
      shift
      certtype=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

$subcmd "$@"


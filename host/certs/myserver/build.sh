#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

servername=${servername:-"myserver"}
serveraddr=192.168.0.98

output_dir="$top_dir"

server=`echo $servername | tr '[:upper:]' '[:lower:]'`

database="$output_dir/db"
password=${password:-"secret"}

csrfile=${output_dir}/${server}.csr
crtfile=${output_dir}/${server}.crt
  
p12file=${output_dir}/${server}.p12
pemfile=${output_dir}/${server}.key.pem
keyfile=${output_dir}/${server}.key

help()
{
cat - << EOS
usage : $0 <target>
  target :
    clean
    init
    csr     create server.csr
    crt     create server.crt
    load    import server.crt
    list    show list of certificate
    save    export server.key
EOS

}

all()
{
  #destroy
  init

  csr
  crt
  load

  save
}


clean()
{
  rm -f ${output_dir}/*.csr
  rm -f ${output_dir}/*.crt
  rm -f ${output_dir}/*.key
  rm -f ${output_dir}/*.pem
  rm -f ${output_dir}/*.p12
}

destroy()
{
  rm -rf ${output_dir}/db
  rm -f  ${servername}.*
}

list() {
  certutil -L -d ${database}
}

db() {
  rm -rf ${database}
  mkdir -p ${database}

  echo create database ${database}
  dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
  certutil -N -d ${database} --empty-password
  rm -f noise.bin
}

csr()
{
	echo "create csr, $csrfile"
	mkdir -p ${output_dir}
	echo ${password} > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	
    certutil -R \
		-d ${database} \
		-s "cn=$server" \
		-f password.txt \
		-z noise.bin \
		-o $csrfile \
		-a 

	rm -f password.txt noise.bin
}

init() {
  db
}

crt()
{
  cd ../ca
  pwd
  sh ./build.sh crt -i ${csrfile} -o ${crtfile} ${serveraddr}
  cd $top_dir 
}


load()
{
	echo "import $crtfile"
	certutil -A -d ${database} \
		-n "${servername}" \
		-t ",," \
		-i $crtfile
}

save()
{
	p12
	seckey
	jks
}

p12()
{
  echo export $p12file
  pk12util -o $p12file \
    -n "${servername}" \
    -d ${database} \
    -W "${password}"
}

seckey()
{
	echo export $pemfile
	openssl pkcs12 \
		-in  $p12file \
		-nocerts \
		-out $pemfile \
		-password "pass:${password}" \
		-nodes

    openssl rsa -in  $pemfile -out $keyfile
}

jks()
{
    destkeypass="changeit"

	echo export $output_dir/$server.jks
	rm -f $output_dir/$server.jks
	LANG=C keytool -importkeystore \
		-srckeystore $output_dir/$server.p12 \
		-srcstoretype PKCS12 \
		-deststoretype JKS \
		-destkeystore $output_dir/$server.jks \
		-storepass "${password}" \
		-keypass "${password}" \
		-destkeypass "${destkeypass}" \
		-srcstorepass "${password}"

	# ubuntu:
	# edit /etc/default/jenkins
	#
	# HTTPS_PORT=8443
	# KEYSTORE=/var/lib/jenkins/jenkins.jks
	# PASSWORD=secret
	# JENKINS_ARGS="--webroot=/var/cache/$NAME/war --httpsPort=$HTTPS_PORT --https    KeyStore=$KEYSTORE --httpsKeyStorePassword=$PASSWORD --httpPort=$HTTP_PORT"
	#

}

vars()
{
  echo "csrfile : $csrfile"
}

args=""
input=""
output=""

while [ "$#" != "0" ]; do
  case $1 in
    -c | --certname)
      shift
      certname=$1
      ;;
    -i | --input)
      shift
      input=$1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    -s | --server)
      shift
      server=$1
      ;;
    -a | --address)
      shift
      address=$1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "${args}" ]; then
  help 
  exit 1
fi

for target in $args; do
  LANG=C type -t $target | grep 'function' > /dev/null 2>&1
  if [ "$?" = "0" ]; then
    $target
  else
    echo target \"$target\" is not a function.
  fi
done


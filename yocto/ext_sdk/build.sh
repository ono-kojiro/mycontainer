#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

. ~/poky_sdk/environment-setup-aarch64-poky-linux > /dev/null
  
recipe_name=myapp
url="https://github.com/ono-kojiro/myapp.git;branch=main"

poky_sdk=~/poky_sdk
workspace=$poky_sdk/workspace

local_conf=$poky_sdk/conf/local.conf

usage()
{
  echo "usage : $0 [options] target1 target2 ..."
  echo "   init, config, add, update, edit, build, package"
}

help()
{
  usage
}

all()
{
  init
  config
  add
  update
  build
}

init()
{
  mkdir -p $workspace/conf/

  cat - << 'EOS' > $workspace/conf/layer.conf
BBPATH =. "${LAYERDIR}:"
BBFILES += "${LAYERDIR}/recipes/*/*.bb \
            ${LAYERDIR}/appends/*.bbappend"
BBFILE_COLLECTIONS += "workspacelayer"
BBFILE_PATTERN_workspacelayer = "^${LAYERDIR}/"
BBFILE_PATTERN_IGNORE_EMPTY_workspacelayer = "1"
BBFILE_PRIORITY_workspacelayer = "99"

EOS

}

config()
{
  :
}

add()
{
  cmd="devtool add $recipe_name $url"
  echo $cmd; $cmd
}

update()
{
  recipefile=$workspace/recipes/$recipe_name/${recipe_name}_git.bb

  grep 'do_configure_prepend' $recipefile > /dev/null 2>&1
  res=$?
  if [ $res -ne 0 ]; then
    cat - << 'EOS' >> $recipefile 
do_configure_prepend() {
  export PATH=/home/kojiro/tmp/autoconf-2.71/usr/bin:$PATH
  autoreconf -vi
}

EOS
  else
    echo skip updating $recipefile
  fi
  
  sed -i -e 's|^inherit cmake|inherit autotools|' $recipefile
 
  bbappend=$workspace/appends/${recipe_name}_git.bbappend
  grep 'EXTERNALSRC_BUILD' $bbappend > /dev/null 2>&1
  res=$?
  if [ $res -ne 0 ]; then
    {
      echo 'EXTERNALSRC_BUILD = "${EXTERNALSRC}"'
    } >> $workspace/appends/${recipe_name}_git.bbappend
  else
    echo skip updating $bbappend
  fi

  sed -i -e 's|^DL_DIR = .*"|DL_DIR = "/home/share/yocto/downloads"|' $local_conf

}

edit()
{
  devtool edit-recipe $recipe_name
}

build()
{
  cmd="devtool build $recipe_name"
  echo $cmd; $cmd
}

image()
{
  cmd="devtool build-image core-image-minimal"
  echo $cmd; $cmd
}

run()
{
  disk1="${top_dir}/disk1.ext4"
  if [ ! -e "$disk1" ]; then
    dd if=/dev/zero of=$disk1 bs=1024K count=1024
  fi

  params="-m 4096 -smp 4"
  params="$params -device virtio-blk-device,drive=disk1"
  params="$params -drive id=disk1,file=$disk1,if=none,format=raw"

  bootparams="root=/dev/vdb"
  image="core-image-minimal"

  runqemu nographic slirp ${machine} \
    qemuparams="$params" bootparams="$bootparams" \
    $image
  cd ${top_dir}
}

package()
{
  cmd="devtool package $recipe_name"
  echo $cmd; $cmd
}

check()
{
  :
}

install()
{
  :
}

mclean()
{
  rm -rf ~/poky_sdk/workspace/*
}

all()
{
  clean
  init
  add
  update
  build
  package
}

while true ; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    -l | --logfile)
      shift
      logfile=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  echo "ERROR : no target"
  usage
  exit 1
fi

for target in "$@"; do
  LANG=C type "$target" | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done


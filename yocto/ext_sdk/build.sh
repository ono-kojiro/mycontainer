#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

. ~/poky_sdk/environment-setup-aarch64-poky-linux > /dev/null

recipe_name=myapp
workspace=~/poky_sdk/workspace

usage()
{
  echo "usage : $0 [options] target1 target2 ..."
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

configure()
{
  :
}

add()
{
  cmd="devtool add $recipe_name git@bitbucket.org:unixdo/myapp.git"
  echo $cmd; $cmd
}

update()
{
  recipefile=$workspace/recipes/$recipe_name/${recipe_name}_git.bb

  cat - << 'EOS' >> $recipefile

do_configure_prepend() {
  autoreconf -vi
}
EOS

  #cmd="cat ${recipe_name}_git.bb append.bb"
  #echo "$cmd > $recipefile"; $cmd > $recipefile

  echo 'EXTERNALSRC_BUILD = "${EXTERNALSRC}"' >> $workspace/appends/${recipe_name}_git.bbappend
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

clean()
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


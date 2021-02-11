#!/bin/sh

# create empty image (only /etc, /var)

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=empty

all() {
  clean
  layer
  build
  check
}


clean() {
  rm -rf poky/build/tmp/work/qemuarm64-poky-linux/empty-image/
}

layer() {
  rm -rf meta-$name
  echo "create layer, $name... "
  echo "6\ny\n$name\nn\n" | \
    ./poky/scripts/yocto-layer create $name > /dev/null

  mkdir -p meta-$name/recipes-example/images

  image_bb=meta-$name/recipes-example/images/${name}-image.bb

  cat - << 'EOS' > $image_bb
SUMMARY = "Minimal $name Image"

LICENSE = "MIT"

inherit image

PREFERRED_PROVIDER_virtual/kernel = "linux-dummy"

IMAGE_INSTALL = ""
IMAGE_LINGUAS = ""
PACKAGE_INSTALL = ""

#IMAGE_INSTALL_append = ""

#IMAGE_FEATURES_append = " empty-root-password"
#IMAGE_INSTALL = " openssh"

do_install() {
  install -d ${D}/home/root
}

EOS

  echo "done"
}


#cat $image_bb

build() {
  cd poky/build

  bitbake-layers remove-layer ../../meta-$name
  bitbake-layers add-layer ../../meta-$name

  echo "bitbake ${name}-image"
  bitbake ${name}-image

  cd $top_dir
}

check() {
  image_tar=poky/build/tmp/work/qemuarm64-poky-linux/$name-image/1.0-r0/deploy-$name-image-image-complete/$name-image-qemuarm64.tar.bz2

  tar tjvf $image_tar
}

if [ -z "$@" ]; then
  all
fi

for target in "$@" ; do
    LANG=C type $target | grep function > /dev/null 2>&1
    res=$?
    if [ "x$res" = "x0" ]; then
        $target
    else
        make $target
    fi
done


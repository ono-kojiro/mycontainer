#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=hoge

rm -rf meta-$name

echo create layer, $name
echo "6\ny\n$name\nn\n" | \
  ./poky/scripts/yocto-layer create $name > /dev/null

mkdir -p meta-hoge/recipes-example/images

image_bb=meta-hoge/recipes-example/images/${name}-image.bb

cat - << EOS > $image_bb
SUMMARY = "Minimal $name Image"

LICENSE = "MIT"

inherit core-image

CORE_IMAGE_BASE_INSTALL = "$name"
IMAGE_LINGUAS = ""
IMAGE_FSTYPES = "tar.bz2"
IMAGE_TYPES = ""
DISTRO_EXTRA_RDEPENDS = ""
EOS

#cat $image_bb


cd poky/build

bitbake-layers remove-layer ../../meta-$name
bitbake-layers add-layer ../../meta-$name

bitbake ${name}-image

cd $top_dir


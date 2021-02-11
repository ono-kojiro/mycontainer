#!/bin/sh

# create empty image (only /etc, /var)

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=empty

rm -rf meta-$name

echo create layer, $name
echo "6\ny\n$name\nn\n" | \
  ./poky/scripts/yocto-layer create $name > /dev/null

mkdir -p meta-hoge/recipes-example/images

image_bb=meta-hoge/recipes-example/images/${name}-image.bb

cat - << EOS > $image_bb
SUMMARY = "Minimal $name Image"

LICENSE = "MIT"


#PREFERRED_PROVIDER_virtual/kernel = "linux-dummy"

IMAGE_INSTALL = ""
IMAGE_LINGUAS = ""
PACKAGE_INSTALL = ""

inherit image

EOS

#cat $image_bb


cd poky/build

bitbake-layers remove-layer ../../meta-$name
bitbake-layers add-layer ../../meta-$name

bitbake ${name}-image

cd $top_dir


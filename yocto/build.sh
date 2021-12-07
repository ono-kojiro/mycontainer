#!/bin/sh


top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

if [ ! -e ./config.bashrc ]; then
    echo "ERROR : no config.bashrc in $top_dir"
    echo "Please create $top_dir/config.bashrc"
    echo "and define build_dir variable."
    exit 1
fi

. ./config.bashrc


#image=core-image-minimal-dev
image=core-image-base
#image=core-image-minimal

which chrpath
res=$?
if [ "$res" != "0" ]; then
  echo "ERROR : need chrpath"
  exit $res
fi

which gawk
res=$?
if [ "$res" != "0" ]; then
  echo "ERROR : need gawk"
  exit $res
fi

which makeinfo
res=$?
if [ "$res" != "0" ]; then
  echo "ERROR : need makeinfo(texinfo)"
  exit $res
fi


help()
{
    usage
}

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
    echo ""
    echo "  target"
    echo "    clone"
    echo "    checkout"
    echo "    config"
    echo "    build"
    echo "    "
    echo "    run"
    echo "    "
    echo "    clean"
    echo "    mclean"
    echo ""
    echo "    show_layers"
    echo "    show_recipes"
    echo "    show_images"
    echo ""
    echo "  variables"
    echo "    build_dir   $build_dir"
	exit 0
}

all()
{
	help
}
        
clone()
{
    mkdir -p $build_dir
    cd $build_dir

    if [ ! -d meta-openembedded ]; then
        git clone \
            https://git.openembedded.org/meta-openembedded
    else
        echo skip to clone meta-openembedded
    fi

    if [ ! -d meta-virtualization ]; then
        git clone \
            https://git.yoctoproject.org/git/meta-virtualization
    else
        echo skip to clone meta-virtualization
    fi

    if [ ! -d meta-cloud-services ]; then
        git clone \
          https://git.yoctoproject.org/git/meta-cloud-services
    else
        echo skip to clone meta-cloud-services
    fi

    if [ ! -d poky ]; then
        git clone \
            https://git.yoctoproject.org/git/poky
    else
        echo skip to clone poky
    fi

    cd $top_dir
}

checkout()
{
    cd $build_dir

    if [ ! -d meta-openembedded ]; then
        echo ERROR : no meta-openembedded directory
    else
        git -C meta-openembedded checkout rocko
    fi

    if [ ! -d meta-virtualization ]; then
        echo ERROR : no meta-virtualization directory
    else
        git -C meta-virtualization checkout rocko
    fi
    
    if [ ! -d meta-cloud-services ]; then
        echo ERROR : no meta-cloud-services directory
    else
	git -C meta-cloud-services checkout rocko
    fi

    if [ ! -d poky ]; then
        echo ERROR : no poky directory
    else
        git -C poky checkout rocko
    fi

    cd $top_dir
}

ls()
{
  command ls -l $build_dir
}


config()
{
    mkdir -p $build_dir
    cd $build_dir

    cd poky
    echo removing build/conf...
    rm -rf build/conf
    echo done.
    . ./oe-init-build-env

   {
     echo ""
     echo "BBLAYERS_append = \" ../../meta-openembedded/meta-oe\""
     echo "BBLAYERS_append = \" ../../meta-openembedded/meta-python\""
     echo "BBLAYERS_append = \" ../../meta-openembedded/meta-networking\""
     echo "BBLAYERS_append = \" ../../meta-openembedded/meta-filesystems\""
     echo "BBLAYERS_append = \" ../../meta-virtualization\""
     echo "#BBLAYERS_append = \" ../../meta-cloud-services/meta-openstack\""
     echo "BBLAYERS_append = \" ../../meta-openembedded/meta-webserver\""
     echo "BBLAYERS_append = \" $top_dir/meta-container/meta-mylayer\""
     echo "BBLAYERS_append = \" $top_dir/meta-misc\""
     echo ""
   } >> conf/bblayers.conf
     
     # echo "BBLAYERS_append = \" $top_dir/meta-observability\""

    sed -i.bak \
      -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' \
      conf/local.conf
    
  sed -i.bak \
    -e 's|^MACHINE\s*??=\s*"qemux86"|MACHINE ??= "qemuarm64"|' \
    conf/local.conf

  cat - << "EOS" >> conf/local.conf
EXTRA_IMAGE_FEATURES_append = " tools-profile"

#40 Gbytes of extra space with the line:
IMAGE_ROOTFS_EXTRA_SPACE = "41943040"

DISTRO_FEATURES_append = " virtualization"

# LXC
IMAGE_INSTALL_append = " lxc cgroup-lite"
IMAGE_INSTALL_append = " dropbear"
IMAGE_INSTALL_append = " gnupg"
IMAGE_INSTALL_append = " nfs-utils"

# Docker
IMAGE_INSTALL_append = " docker"
#IMAGE_INSTALL_append = " docker-compose"
IMAGE_INSTALL_append = " docker-contrib"
#IMAGE_INSTALL_append = " connman"
#IMAGE_INSTALL_append = " connman-client"
#IMAGE_INSTALL_append = " python3-docker-compose"

CORE_IMAGE_EXTRA_INSTALL_append = " kernel-modules"

# systemd
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

SERIAL_CONSOLES_CHECK = "${SERIAL_CONSOLES}"

IMAGE_FEATURES += " package-management"
PACKAGE_CLASSES ?= " package_rpm"

IMAGE_INSTALL_append = " apache2"
IMAGE_INSTALL_append = " stress"
IMAGE_INSTALL_append = " htop"

IMAGE_INSTALL_append = " python3-pip"
IMAGE_INSTALL_append = " python3-flask"
IMAGE_INSTALL_append = " fio"

EOS


  cd $top_dir
}

build()
{
    cd $build_dir/poky
    . ./oe-init-build-env
    bitbake $image
    cd $top_dir
}

run()
{
    cd $build_dir/poky

    params="-m 4096"
    params="$params -smp 4"

    . ./oe-init-build-env

    disk1="$top_dir/disk1.ext4"
    if [ ! -e "$disk1" ]; then
      qemu-img create -f qcow2 $disk1 16G
    fi

    params="$params -device virtio-blk-device,drive=disk1"
    params="$params -drive id=disk1,file=$disk1,if=none,format=raw"

    bootparams=""
    bootparams="$bootparams root=/dev/vdb"

    runqemu nographic qemuarm64 \
      qemuparams="$params" bootparams="$bootparams" \
      $image
    cd $top_dir
}

show_images()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake-layers show-recipes | grep 'core-image-'
    cd $top_dir
}

show_recipes()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake-layers show-recipes
    cd $top_dir
}

show_layers()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake-layers show-layers
    cd $top_dir
}

info()
{
    echo "top_dir   : $top_dir"
    echo "build_dir : $build_dir"
    echo "image     : $image"
}

clean()
{
    :
}

mclean()
{
	rm -rf $build_dir/poky/build
}

sdk()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake -c populate_sdk $image
    cd $top_dir

	echo "generated installer:"
	echo poky/build/tmp/deploy/sdk/poky-glibc-x86_64-core-image-base-aarch64-toolchain-2.4.4.sh
}

sdk_ext()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake -c populate_sdk_ext $image
    cd $top_dir

	# install extensible sdk
	# $ sh tmp/deploy/sdk/poky-glibc-x86_64-core-image-base-aarch64-toolchain-ext-2.4.4.sh

    # $ source ~/poky_sdk/environment-setup-aarch64-poky-linux
	# $ devtool build-image core-image-minimal

	# run qemu using devtool (escape white space!)
	# $ devtool runqemu nographic qemuparams="-m\ 4096" qemuparams="-smp\ 4" core-image-minimal

}


if [ "x$@" = "x" ]; then
  usage
  exit
fi

logfile=""

while getopts hvl: option
do
	case "$option" in
		h)
			usage;;
		v)
			verbose=1;;
		l)
			logfile=$OPTARG;;
		*)
			echo unknown option "$option";;
	esac
done

shift $(($OPTIND-1))

if [ "x$logfile" != "x" ]; then
	echo logfile is $logfile
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

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


image=core-image-minimal-dev

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
	config
	build
}
        
clone()
{
    mkdir -p $build_dir
    cd $build_dir

    if [ ! -d meta-openembedded ]; then
	    git clone \
            git://github.com/openembedded/meta-openembedded.git
    else
        echo skip to clone meta-openembedded
    fi

    if [ ! -d meta-virtualization ]; then
        git clone \
            git://git.yoctoproject.org/meta-virtualization
    else
        echo skip to clone meta-virtualization
    fi

    if [ ! -d poky ]; then
        git clone \
            git://git.yoctoproject.org/poky.git
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
    cd $build_dir

    cd poky
    echo removing build/conf...
    rm -rf build/conf
    echo done.
    . ./oe-init-build-env

    sed -i.bak \
      -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' \
      conf/local.conf
    
  sed -i.bak \
    -e 's|^MACHINE\s*??=\s*"qemux86"|MACHINE ??= "qemuarm64"|' \
    conf/local.conf

  cat - << "EOS" >> conf/local.conf

DISTRO_FEATURES_append = " virtualization"
IMAGE_INSTALL_append = " lxc cgroup-lite"
IMAGE_INSTALL_append = " dropbear"
IMAGE_INSTALL_append = " gnupg"
IMAGE_INSTALL_append = " nfs-utils"

DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

SERIAL_CONSOLES_CHECK = "${SERIAL_CONSOLES}"

IMAGE_INSTALL_append = " apache2"
IMAGE_INSTALL_append = " stress"
IMAGE_INSTALL_append = " htop"

EOS

  bitbake-layers add-layer ../../meta-openembedded/meta-oe
  bitbake-layers add-layer ../../meta-openembedded/meta-python
  bitbake-layers add-layer ../../meta-openembedded/meta-networking
  bitbake-layers add-layer ../../meta-openembedded/meta-filesystems
  bitbake-layers add-layer ../../meta-virtualization
  bitbake-layers add-layer ../../meta-openembedded/meta-webserver

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
    . ./oe-init-build-env
    runqemu nographic qemuarm64 $image
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

for target in "$@ $TARGETS" ; do
	LANG=C type $target | grep function > /dev/null 2>&1
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		make $target
	fi
done

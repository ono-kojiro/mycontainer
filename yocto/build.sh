#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

cd $top_dir

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
	exit 0
}

all()
{
	config
	build
}
        
checkout()
{
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
}

branch()
{
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
}

config()
{
    cd poky
    rm -rf build
    . ./oe-init-build-env
    sed -i.bak -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' conf/local.conf
    sed -i.bak -e 's|^MACHINE\s*??=\s*"qemux86"|MACHINE ??= "qemuarm64"|' conf/local.conf
    #sed -i.bak -e 's|^#DL_DIR\s*?=\s*"|DL_DIR ?= |' conf/local.conf

    python $top_dir/add_layers.py < conf/bblayers.conf > tmp.conf
    mv tmp.conf conf/bblayers.conf
    cd $top_dir
}

build()
{
    cd poky
    . ./oe-init-build-env
    bitbake core-image-minimal
    cd $top_dir
}

clean()
{
    :
}

mclean()
{
	rm -rf poky/build
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
	LANG=C type $target | grep function
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		make $target
	fi
done


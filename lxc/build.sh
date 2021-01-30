#!/bin/sh


top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

template=mytemplate

#template=sshd
#template=download
container=mybusybox

help()
{
    usage
}

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
    echo ""
    echo "  target"
    echo "  start"
	exit 0
}

all()
{
	config
	build
}

create()
{
    #lxc-create -t ./lxc-busybox$template -n $container
    lxc-create -t `pwd`/$template -n $container
}

delegate()
{
    systemd-run --unit=myshell --user --scope \
        -p "Delegate=yes" \
    lxc-start -n $container
}

start()
{
    rm -f mybuxybox.log
	chmod 755 ~/.local ~/.local/share
    lxc-start -n $container -l debug -o ${container}.log
}

ls()
{
	lxc-ls -f
}

attach()
{
	#lxc-attach -n $container -- /bin/sh
	lxc-attach -n $container -- /bin/bash
}

stop()
{
	lxc-stop -n $container
}

destroy()
{
	stop
	lxc-destroy -n $container
}

clean()
{
	rm -f ${container}.log
	stop
	destroy
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
		echo "ERROR : $target is not shell function"
	fi
done

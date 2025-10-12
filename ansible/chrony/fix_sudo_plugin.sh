#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
#cd $top_dir

patchfile="$top_dir/0001-fix_for_sudo_rs.patch"
site_packages=`python3 -c "import site; print(site.getsitepackages()[0])"`

patch -d $site_packages -p0 -i $patchfile


#!/bin/sh

rm -rf ./BUILDROOT
	rpmbuild --bb libmylib.spec \
		--build-in-place \
		--buildroot=`pwd`/BUILDROOT \
		--define "_rpmdir `pwd`/RPMS" \
		--define "_srcrpmdir `pwd`/RPMS" \
		--define "_specdir   `pwd`" \
		--define "_builddir  `pwd`/BUILD" \
		--target aarch64-poky-linux



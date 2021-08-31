ACLOCAL_AMFLAGS = -I config

SUBDIRS = \
  src \
  tests

EXTRA_DIST = libmylib.spec

dist_pkgdata_DATA = LICENSE

rpm:
	$(MAKE) dist
	rm -rf ./BUILDROOT
	rpmbuild --bb libmylib.spec \
		--build-in-place \
		--buildroot=`pwd`/BUILDROOT \
		--define "_rpmdir `pwd`/RPMS" \
		--define "_srcrpmdir `pwd`/RPMS" \
		--define "_specdir   `pwd`" \
		--define "_builddir  `pwd`/BUILD" \
		--target aarch64-poky-linux

install-rpm:
	sudo rpm -vhi \
    	--prefix /opt/poky/2.4.4/sysroots/aarch64-poky-linux/usr \
    	--ignorearch libmylib-0.0.1-1.aarch64.rpm

uninstall-rpm:
	sudo rpm -e libmylib

reinstall-rpm:
	$(MAKE) uninstall-rpm install-rpm


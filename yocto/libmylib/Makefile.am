ACLOCAL_AMFLAGS = -I config

SUBDIRS = \
  src \
  tests

EXTRA_DIST = libmylib.spec

rpm:
	$(MAKE) dist
	cp -f libmylib-0.0.1.tar.gz ~/rpmbuild/SOURCES/
	rpmbuild -bb --target aarch64-poky-linux libmylib.spec
	cp -f ~/rpmbuild/RPMS/aarch64/libmylib-0.0.1-1.aarch64.rpm .

install-rpm:
	sudo rpm -vhi \
    	--prefix /opt/poky/2.4.4/sysroots/aarch64-poky-linux/usr \
    	--ignorearch libmylib-0.0.1-1.aarch64.rpm

uninstall-rpm:
	sudo rpm -e libmylib

reinstall-rpm:
	$(MAKE) uninstall-rpm install-rpm


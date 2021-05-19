ACLOCAL_AMFLAGS = -I config

SUBDIRS = src

rpm :
	$(MAKE) dist
	cp -f myapp-0.0.1.tar.gz ~/rpmbuild/SOURCES/
	rpmbuild -bb --target=aarch64-poky-linux myapp.spec
	cp -f ~/rpmbuild/RPMS/aarch64/myapp-0.0.1-1.aarch64.rpm .

install-rpm :
	sudo rpm -vhi \
		--prefix /opt/poky/2.4.4/sysroots/aarch64-poky-linux/usr \
		--ignorearch myapp-0.0.1-1.aarch64.rpm

uninstall-rpm:
	sudo rpm -e myapp

reinstall-rpm:
	$(MAKE) uninstall-rpm install-rpm


ACLOCAL_AMFLAGS = -I config

#EXTRA_DIST = Dockerfile

dist_pkgdata_DATA = Dockerfile

rpm :
	rm -rf ./BUILDROOT
	$(MAKE) dist
	rpmbuild -bb mydocker.spec \
		--build-in-place \
		--buildroot=`pwd`/BUILDROOT \
		--define "_rpmdir `pwd`/RPMS" \
		--define "_srcrpmdir `pwd`/SRPMS"

srpm :
	rm -rf ./BUILDROOT
	$(MAKE) dist
	rpmbuild -bs mydocker.spec \
		--build-in-place \
		--buildroot=`pwd`/BUILDROOT \
		--define "_rpmdir `pwd`/RPMS" \
		--define "_srcrpmdir `pwd`/SRPMS" \
		--define "_sourcedir `pwd`"


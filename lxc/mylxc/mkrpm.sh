#!/bin/sh

rm -rf ./BUILDROOT
rpmbuild -bb mylxc.spec \
  --build-in-place \
  --buildroot=`pwd`/BUILDROOT \
  --define "_rpmdir `pwd`/RPMS" \
  --define "_srcrpmdir `pwd`/SRPMS" \
  --define "_specdir   `pwd`" \
  --define "_builddir `pwd`/BUILD"


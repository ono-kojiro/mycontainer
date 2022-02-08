SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"
SRC_URI = "git://github.com/ono-kojiro/libmylib.git;branch=main \
          "

SRC_URI[md5sum] = "2f6bb25d06ceb1c572952445ab2a2bab"
SRC_URI[sha256sum] = "3de2b303becdea9047b96308659a2b0dd7823e0376d8f1e0396890b15287966c"

PV = "1.0+git${SRCREV}"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

PACKAGES = "${PN}-dev ${PN}-dbg ${PN}-staticdev ${PN}"

RDEPENDS_${PN}-staticdev = ""
RDEPENDS_${PN}-dev       = ""
RDEPENDS_${PN}-dbg       = ""

PROVIDES = "${PN}"

inherit autotools pkgconfig

do_configure_prepend() {
  cd ${S}
  autoreconf -vi
}

do_compile_prepend() {
  echo "in do_compile_prepend"
  cwd=`pwd`
  echo "CWD is $cwd"
  cd ${S}
}

do_install_prepend() {
  cd ${S}
}


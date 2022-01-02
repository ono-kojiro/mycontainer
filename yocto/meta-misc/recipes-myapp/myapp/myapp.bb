SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"

# git@bitbucket.org:unixdo/myapp.git
SRC_URI = "git://git@bitbucket.org/unixdo/myapp.git;protocol=ssh;branch=master \
          "

PV = "1.0+git${SRCPV}"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

DEPENDS_append = " libmylib"
#RDEPENDS_${PN} += " libmylib"

do_configure() {
  autoreconf -vi
}

do_compile() {
  CC=$CC LD=$LD sh configure \
    --prefix=/usr \
    --host=aarch64-poky-linux

  make
}

do_install() {
  make install DESTDIR=${D}
}


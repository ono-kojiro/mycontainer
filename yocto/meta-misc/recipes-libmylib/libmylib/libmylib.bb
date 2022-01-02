SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"
SRC_URI = "git://git@bitbucket.org/unixdo/libmylib.git;protocol=ssh;branch=master \
          "

PV = "1.0+git${SRCPV}"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

PACKAGES = "${PN}-dev ${PN}-dbg ${PN}-staticdev ${PN}"

RDEPENDS_${PN}-staticdev = ""
RDEPENDS_${PN}-dev       = ""
RDEPENDS_${PN}-dbg       = ""

PROVIDES = "${PN}"

inherit pkgconfig

do_configure() {
  autoreconf -vi
}

do_compile() {
  CC=$CC LD=$LD sh configure \
    --prefix=/usr \
	--host=aarch64-poky-linux \
    --disable-check
  make
}

do_install() {
  make install DESTDIR=${D}
}


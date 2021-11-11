SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"
SRC_URI = "file://myapp.c \
 file://CMakeLists.txt \
 file://cmake-3.19.8.bashrc \
"

S = "${WORKDIR}"

DEPENDS_append = " libmylib"
#RDEPENDS_${PN} += " libmylib"

do_compile() {
  pwd
  ls
  . ./cmake-3.19.8.bashrc
  cmake -DCMAKE_INSTALL_PREFIX=/usr .
  make
}

do_install() {
  make install DESTDIR=${D}
}


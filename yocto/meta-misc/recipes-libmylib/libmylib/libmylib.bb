SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"
SRC_URI = "file://mylib.c"
SRC_URI_append = " file://mylib.h"
SRC_URI_append = " file://cmake-3.19.8.bashrc"
SRC_URI_append = " file://CMakeLists.txt"
S = "${WORKDIR}"

do_compile() {
  pwd
  ls
  cat cmake-3.19.8.bashrc
  . ./cmake-3.19.8.bashrc
  cmake -DCMAKE_INSTALL_PREFIX=/usr .
  make
}

do_install() {
  pwd
  ls
  make install DESTDIR=${D}
}


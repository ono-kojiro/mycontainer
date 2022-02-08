SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"

SRC_URI = "git://github.com/ono-kojiro/myapp.git;branch=main \
          "
SRC_URI[md5sum] = "fcf5f8ac4f6181806667d9e0d5640e7f"
SRC_URI[sha256sum] = "dbd4f3a1223dfa9ce8a6e8b6d336b63ddb2bea4cc8b7d238478619d170768fed"

PV = "1.0+git${SRCREV}"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

DEPENDS_append = " libmylib"
#RDEPENDS_${PN} += " libmylib"

inherit autotools

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



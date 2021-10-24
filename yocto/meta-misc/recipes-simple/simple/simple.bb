SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://simple.c"
S = "${WORKDIR}"

do_compile() {
  ${CC} ${LDFLAGS} simple.c -o simple
}

do_install() {
  install -d ${D}${bindir}
  install -m 0755 simple ${D}${bindir}
}


FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://config_xfs_fs.cfg"

do_configure_append() {
  cat ${WORKDIR}/*.cfg >> ${B}/.config
}


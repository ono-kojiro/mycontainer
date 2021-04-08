FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "file://config_xfs_fs.cfg"

do_configure_append() {
  #cat ${WORKDIR}/*.cfg >> ${B}/.config
  echo current : ${B}/.config
  cat ${B}/.config

  echo additional config ${WORKDIR}/*.cfg
  cat ${WORKDIR}/*.cfg

  ${S}/scripts/kconfig/merge_config.sh \
    -m -O ${B}/ ${B}/.config ${WORKDIR}/*.cfg
  
  echo merged ${B}/.config
  cat ${B}/.config
}


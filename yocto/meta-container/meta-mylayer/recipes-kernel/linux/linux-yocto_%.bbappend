#
# $ bitbake linux-yocto -c kernel_configcheck -f
#
# $ bitbake linux-yocto -c savedefconfig
#
# $ bitbake virtual/kernel -e | grep -e 'LINUX_VERSION='
#
# $ bitbake virtual/kernel -c cleansstate
#

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://config_macvtap.cfg"
SRC_URI_append = " file://config_hotplug.cfg"

do_configure_append() {
  cat ${WORKDIR}/*.cfg >> ${B}/.config
  #echo current : ${B}/.config
  #cat ${B}/.config

  #echo additional config ${WORKDIR}/*.cfg
  #cat ${WORKDIR}/*.cfg

  #${S}/scripts/kconfig/merge_config.sh \
  #  -m -O ${B}/ ${B}/.config ${WORKDIR}/*.cfg
  
  #echo merged ${B}/.config
  #cat ${B}/.config
}

KERNEL_MODULE_AUTOLOAD += "macvlan"
KERNEL_MODULE_AUTOLOAD += "macvtap"


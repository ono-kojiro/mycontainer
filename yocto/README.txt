LXC sample on Yocto

Configuration
$ bitbake -c menuconfig virtual/kernel

config:
tmp/work/qemuarm64-poky-linux/linux-yocto/4.12.28+gitAUTOINC+2ae65226f6_e562267bae-r0/linux-qemuarm64-standard-build/.config

https://www.headdesk.me/LXC

Change TimeZone
- install tzdata
- ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime


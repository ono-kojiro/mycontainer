#!/bin/sh

apt-get -qq update
apt-get -qq upgrade
apt-get -qq install locales
sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen
locale-gen ja_JP.UTF-8
update-locale LANG=ja_JP.UTF-8
apt-get -qq clean
rm -rf /var/lib/apt/lists/*



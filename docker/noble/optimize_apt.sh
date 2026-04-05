#!/bin/sh
set -xe 

echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup

echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean

echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean

echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean

echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages
echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes

echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

rm -rf /var/lib/apt/lists/*
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
mkdir -p /run/systemd && echo 'docker' > /run/systemd/container


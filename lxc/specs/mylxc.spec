%global _binaries_in_noarch_packages_terminate_build 0
%global __os_install_post /usr/lib/rpm/brp-compress

%global debug_package %{nil}

%define _build_id_links none

%global target aarch64-poky-linux

Name: mylxc
Version: 0.0.1
Release: 1%{?dist}
Summary: lxc sample
Group: none
License: BSD	
URL: http://example.com
Source0: %{name}-%{version}.tar.gz

BuildArch: noarch
#BuildRequires: aarch64-poky-linux-gcc
#Requires: bash

%description
LXC sample

%prep
%setup -q -n %{name}

%build

%install
mkdir -p %{buildroot}/var/lib/lxc/mylxc
install config %{buildroot}/var/lib/lxc/mylxc/config
find rootfs -type d -exec install -d "{}" "%{buildroot}/var/lib/lxc/%{name}/{}" \;
find rootfs -type f -exec install -D "{}" "%{buildroot}/var/lib/lxc/%{name}/{}" \;

%clean
rm -rf $RPM_BUILD_ROOT

%files
%doc
/var/lib/lxc/mylxc/config
/var/lib/lxc/mylxc/rootfs
/var/lib/lxc/mylxc/rootfs/etc/group
/var/lib/lxc/mylxc/rootfs/etc/machine-id
/var/lib/lxc/mylxc/rootfs/etc/passwd
/var/lib/lxc/mylxc/rootfs/etc/ssh/sshd_config
/var/lib/lxc/mylxc/rootfs/etc/udev/hwdb.bin
/var/lib/lxc/mylxc/rootfs/run-dhcp

%changelog


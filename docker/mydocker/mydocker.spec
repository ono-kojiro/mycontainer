%global _binaries_in_noarch_packages_terminate_build 0
%global __os_install_post /usr/lib/rpm/brp-compress

%global debug_package %{nil}

%define _build_id_links none

%global target aarch64-poky-linux

Name: mydocker
Version: 0.0.1
Release: 1%{?dist}
Summary: docker sample
Group: none
License: BSD	
URL: http://example.com
Source0: %{name}-%{version}.tar.gz

BuildArch: noarch
#BuildRequires: aarch64-poky-linux-gcc
#Requires: bash

%description
Docker sample

%prep
%setup -q -n %{name}

%build
%configure --prefix=/usr

%install
make install DESTDIR=%{buildroot}

%post
cd /usr/share/mydocker
mkdir tmp
docker build --tag myimage .

rm -rf tmp

docker create \
  -it \
  --name mycontainer \
  -v /bin:/bin \
  -v /lib:/lib \
  -v /usr/bin:/usr/bin \
  -v /usr/lib:/usr/lib \
  -v /usr/lib64:/usr/lib64 \
  -v /sbin:/sbin \
  --network host \
  myimage \
  /bin/bash

docker start mycontainer

%postun
docker stop mycontainer
docker rm   mycontainer
docker rmi  myimage

%clean

%files
%{_prefix}/share/mydocker/Dockerfile

%changelog


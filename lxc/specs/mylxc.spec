%global debug_package %{nil}
%global _build_id_links none
%global _arch aarch64

%define name mylxc
%define version 1.0.0
%define _configure ../configure

%global cross 1

%if %{cross}
%define host aarch64-linux-gnu
%else
%define host %{_host}
%endif

Name: %{name}
Version: %{version}
Release: 1%{?dist}
Summary: mylxc

Group: Development/Tools
License: GPL
URL: https://example.com/
Source0: https://example.com/mylxc-1.0.0.tar.gz

%if %{cross}
#BuildArch: noarch
#BuildArch: aarch64
%endif

#BuildRequires: make gcc
#Requires: 
#BuildArch: noarch

%description
lxc1

%prep
%setup -q -n %{name}-%{version}

%build
#make %{?_smp_mflags}
#cd ..

%install
mkdir -p %{buildroot}/var/lib/lxc/%{name}

cp -f config %{buildroot}/var/lib/lxc/%{name}/
cp -a rootfs %{buildroot}/var/lib/lxc/%{name}/

%clean

%files
#%doc README
%{_var}/lib/lxc/%{name}/config
%{_var}/lib/lxc/%{name}/rootfs/*



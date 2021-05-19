%global _binaries_in_noarch_packages_terminate_build 0
%global __os_install_post /usr/lib/rpm/brp-compress

%global debug_package %{nil}

%define _build_id_links none

%global target aarch64-poky-linux

%define __requires_exclude libc.so.6
%define __requires_exclude rtld

Name: libmylib
Version: 0.0.1
Release: 1%{?dist}
Summary: RPM example
Group: none
License: BSD	
URL: http://example.com
Source0: %{name}-%{version}.tar.gz

AutoReq : no
Prefix: /usr

%description
RPM sample program

%prep
%setup -q

%build
rm -rf build
mkdir -p build

#autoreconf -vi

cd build
sh ../configure \
	--prefix=%{_prefix} \
	--host=%{_target} \
	--enable-shared \
	--enable-static

make %{?_smp_mflags}
cd ..


%install
cd build
%make_install
rm -rf %{buildroot}/%{_prefix}/lib/.build-id/
cd ..

%check

%clean
echo INFO : clean

%files
%doc
/usr/include/mylib.h
/usr/lib/%{name}*

%changelog


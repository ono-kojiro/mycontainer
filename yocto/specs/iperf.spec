%global debug_package %{nil}
%global _build_id_links none

%define name iperf
%define version 3.10.1
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
Summary: iperf3

Group: Development/Tools
License: GPL
URL: https://github.com/esnet/iperf
Source0: https://github.com/esnet/iperf/archive/refs/tags/3.10.1.tar.gz

%if %{cross}
#BuildArch: noarch
#BuildArch: aarch64
%endif

#BuildRequires: make gcc
#Requires: 
#BuildArch: noarch

%description
iperf3

%prep
%setup -q -n %{name}-%{version}

%build
mkdir -p _build
cd _build
sh ../configure \
	--host=%{host} \
	--build=%{_build} \
        --program-prefix=%{?_program_prefix} \
        --disable-dependency-tracking \
        --prefix=%{_prefix} \
        --exec-prefix=%{_exec_prefix} \
        --bindir=%{_bindir} \
        --sbindir=%{_sbindir} \
        --sysconfdir=%{_sysconfdir} \
        --datadir=%{_datadir} \
        --includedir=%{_includedir} \
        --libdir=%{_libdir} \
        --libexecdir=%{_libexecdir} \
        --localstatedir=%{_localstatedir} \
        --sharedstatedir=%{_sharedstatedir} \
        --mandir=%{_mandir} \
        --infodir=%{_infodir}

make %{?_smp_mflags}
cd ..

%install
cd _build
make install DESTDIR=%{buildroot}
rm -rf %{buildroot}/%{_prefix}/lib/.build-id/
cd ..

%clean

%files
#%doc README
%{_bindir}/*
%{_libdir}/*
%{_includedir}/*
%{_mandir}/man1/iperf3.1.gz
%{_mandir}/man3/libiperf.3.gz


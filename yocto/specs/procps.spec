%global debug_package %{nil}
%global _build_id_links none

%define name procps
%define version 3.3.16
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
Summary: procps

Group: Development/Tools
License: GPL
URL: https://gitlab.com/procps-ng
Source0: https://gitlab.com/procps-ng/procps/-/archive/v3.3.16/procps-v3.3.16.tar.bz2

%if %{cross}
#BuildArch: noarch
#BuildArch: aarch64
%endif

#BuildRequires: make gcc
#Requires: 
#BuildArch: noarch
AutoReqProv: no

%description
iperf3

%prep
%setup -q -n %{name}-v%{version}

%build

#autoreconf -vi
sh autogen.sh

mkdir -p _build
cd _build
ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
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
        --infodir=%{_infodir} \
        --without-ncurses \
        --with-gnu-ld

#CFLAGS=-marm make %{?_smp_mflags}
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
%{_mandir}/man1/*.gz
%{_mandir}/man3/*.gz
%{_mandir}/man5/*.gz
%{_mandir}/man8/*.gz
%{_sbindir}/sysctl                             
%{_datarootdir}/doc/procps-ng/FAQ                    
%{_datarootdir}/doc/procps-ng/bugs.md
%{_datarootdir}/locale/de/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/fr/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/pl/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/pt_BR/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/sv/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/uk/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/vi/LC_MESSAGES/procps-ng.mo
%{_datarootdir}/locale/zh_CN/LC_MESSAGES/procps-ng.mo


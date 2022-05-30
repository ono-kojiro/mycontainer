%global debug_package %{nil}

%define name ldapscripts
%define version 2.0.8

Name:		%{name}
Version:	%{version}
Release:	1%{?dist}
Summary:	ldapscripts

Source0:	https://github.com/martymac/ldapscripts/archive/refs/tags/ldapscripts-%{version}.tar.gz
License: GPL
BuildArch:      noarch

%description
ldapscripts

%prep
%setup -n %{name}-%{name}-%{version}

%build
make PREFIX=/usr LIBDIR=/usr/lib64/%{name} MANDIR=/usr/share/man \
  ETCDIR=/etc/%{name}

%install
make install PREFIX=/usr LIBDIR=/usr/lib64/%{name} MANDIR=/usr/share/man \
  ETCDIR=/etc/%{name} \
  DESTDIR=%{buildroot}

%files
%{_sbindir}/*
%{_libdir}/ldapscripts/runtime
%{_sysconfdir}/%{name}/*
%{_mandir}/man1/*
%{_mandir}/man5/*



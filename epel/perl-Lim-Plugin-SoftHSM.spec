Name:           perl-Lim-Plugin-SoftHSM
Version:        0.14
Release:        1%{?dist}
Summary:        Lim::Plugin::SoftHSM - SoftHSM management plugin for Lim

Group:          Development/Libraries
License:        GPL+ or Artistic
URL:            https://github.com/jelu/lim-plugin-softhsm/
Source0:        lim-plugin-softhsm-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple)
BuildRequires:  perl(Lim) >= 0.16

Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:  perl(Lim) >= 0.16

%description
This plugin lets you manage a SoftHSM installation via Lim.

%package -n perl-Lim-Plugin-SoftHSM-Common
Summary: Common perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.14
%description -n perl-Lim-Plugin-SoftHSM-Common
Common perl libraries for SoftHSM Lim plugin.

%package -n perl-Lim-Plugin-SoftHSM-Server
Summary: Server perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.14
%description -n perl-Lim-Plugin-SoftHSM-Server
Server perl libraries for SoftHSM Lim plugin.

%package -n perl-Lim-Plugin-SoftHSM-Client
Summary: Client perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.14
%description -n perl-Lim-Plugin-SoftHSM-Client
Client perl libraries for communicating with the SoftHSM Lim plugin.

%package -n perl-Lim-Plugin-SoftHSM-CLI
Summary: CLI perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.14
%description -n perl-Lim-Plugin-SoftHSM-CLI
CLI perl libraries for controlling a local or remote SoftHSM installation
via SoftHSM Lim plugin.

%package -n lim-management-console-softhsm
Requires: lim-management-console-common >= 0.16
Summary: SoftHSM Lim plugin Management Console files
Group: Development/Libraries
Version: 0.14
%description -n lim-management-console-softhsm
SoftHSM Lim plugin Management Console files.


%prep
%setup -q -n lim-plugin-softhsm


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
mkdir -p %{buildroot}%{_datadir}/lim/html
mkdir -p %{buildroot}%{_datadir}/lim/html/_softhsm
mkdir -p %{buildroot}%{_datadir}/lim/html/_softhsm/js
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/about.html %{buildroot}%{_datadir}/lim/html/_softhsm/about.html
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/index.html %{buildroot}%{_datadir}/lim/html/_softhsm/index.html
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/js/application.js %{buildroot}%{_datadir}/lim/html/_softhsm/js/application.js
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/config_list.html %{buildroot}%{_datadir}/lim/html/_softhsm/config_list.html
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/config_read.html %{buildroot}%{_datadir}/lim/html/_softhsm/config_read.html
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/show_slots.html %{buildroot}%{_datadir}/lim/html/_softhsm/show_slots.html
install -m 644 %{_builddir}/lim-plugin-softhsm/html/_softhsm/system_information.html %{buildroot}%{_datadir}/lim/html/_softhsm/system_information.html


%check
make test


%clean
rm -rf $RPM_BUILD_ROOT


%files -n perl-Lim-Plugin-SoftHSM-Common
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::SoftHSM.3*
%{perl_vendorlib}/Lim/Plugin/SoftHSM.pm

%files -n perl-Lim-Plugin-SoftHSM-Server
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::SoftHSM::Server.3*
%{perl_vendorlib}/Lim/Plugin/SoftHSM/Server.pm

%files -n perl-Lim-Plugin-SoftHSM-Client
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::SoftHSM::Client.3*
%{perl_vendorlib}/Lim/Plugin/SoftHSM/Client.pm

%files -n perl-Lim-Plugin-SoftHSM-CLI
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::SoftHSM::CLI.3*
%{perl_vendorlib}/Lim/Plugin/SoftHSM/CLI.pm

%files -n lim-management-console-softhsm
%defattr(-,root,root,-)
%{_datadir}/lim/html/_softhsm/about.html
%{_datadir}/lim/html/_softhsm/index.html
%{_datadir}/lim/html/_softhsm/js/application.js
%{_datadir}/lim/html/_softhsm/config_list.html
%{_datadir}/lim/html/_softhsm/config_read.html
%{_datadir}/lim/html/_softhsm/show_slots.html
%{_datadir}/lim/html/_softhsm/system_information.html


%changelog
* Thu Aug 08 2013 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.14-1
- Release 0.14
* Wed Aug 07 2013 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.13-1
- Release 0.13
* Tue Aug 07 2012 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.12-1
- Initial package for Fedora


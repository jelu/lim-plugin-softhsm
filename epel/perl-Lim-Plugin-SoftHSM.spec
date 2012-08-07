Name:           perl-Lim-Plugin-SoftHSM
Version:        0.12
Release:        1%{?dist}
Summary:        Lim::Plugin::SoftHSM - SoftHSM management plugin for Lim

Group:          Development/Libraries
License:        GPL+ or Artistic
URL:            https://github.com/jelu/lim-plugin-softhsm/
Source0:        lim-plugin-softhsm-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
# Needed for test
BuildRequires:  perl(Test::Simple)

Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
...

%package -n perl-Lim-Plugin-SoftHSM-Common
Summary: Common perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-SoftHSM-Common
Common perl libraries for SoftHSM Lim plugin.

%package -n perl-Lim-Plugin-SoftHSM-Server
Summary: Server perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-SoftHSM-Server
Server perl libraries for SoftHSM Lim plugin.

%package -n perl-Lim-Plugin-SoftHSM-Client
Summary: Client perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-SoftHSM-Client
Client perl libraries for communicating with the SoftHSM Lim plugin.

%package -n perl-Lim-Plugin-SoftHSM-CLI
Summary: CLI perl libraries for SoftHSM Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-SoftHSM-CLI
CLI perl libraries for controlling a local or remote SoftHSM installation
via SoftHSM Lim plugin.


%prep
%setup -q -n lim-plugin-softhsm


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'


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


%changelog
* Tue Aug 07 2012 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.12-1
- Initial package for Fedora


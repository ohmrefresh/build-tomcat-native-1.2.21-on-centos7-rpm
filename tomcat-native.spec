Name:           tomcat-native
Version:        1.2.21
Release:        0
Summary:        Tomcat native library

Group:          System Environment/Libraries
License:        Apache-2.0
URL:            http://tomcat.apache.org/tomcat-8.5-doc/apr.html
Source0:        http://www.apache.org/dist/tomcat/tomcat-connectors/native/%{version}/source/%{name}-%{version}-src.tar.gz
Source1:        %{name}-rpmlintrc
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  java-devel
BuildRequires:  jpackage-utils
BuildRequires:  libapr1-devel >= 1.2.1
BuildRequires:  openssl-devel
# Upstream compatibility:
Provides:       tcnative = %{version}-%{release}

%description
Tomcat can use the Apache Portable Runtime to provide superior
scalability, performance, and better integration with native server
technologies.  The Apache Portable Runtime is a highly portable library
that is at the heart of Apache HTTP Server 2.x.  APR has many uses,
including access to advanced IO functionality (such as sendfile, epoll
and OpenSSL), OS level functionality (random number generation, system
status, etc), and native process handling (shared memory, NT pipes and
Unix sockets).  This package contains the Tomcat native library which
provides support for using APR in Tomcat.


%prep
%setup -q -n %{name}-%{version}-src
f=CHANGELOG.txt ; iconv -f iso-8859-1 -t utf-8 $f > $f.utf8 ; mv $f.utf8 $f


%build
cd native
%configure \
    --with-apr=%{_bindir}/apr-1-config \
    --with-java-home=%{java_home} \
    --with-java-platform=2
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make -C native install DESTDIR=$RPM_BUILD_ROOT
# Perhaps a devel package sometime?  Not for now; no headers are installed.
rm -f $RPM_BUILD_ROOT%{_libdir}/libtcnative*.*a
rm -rf $RPM_BUILD_ROOT%{_libdir}/pkgconfig


%clean
rm -rf $RPM_BUILD_ROOT


%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig


%files
%defattr(-,root,root,-)
%doc CHANGELOG.txt LICENSE NOTICE TODO.txt
# Note: unversioned *.so needed here due to how Tomcat loads the lib :(
%{_libdir}/libtcnative*.so*


%changelog

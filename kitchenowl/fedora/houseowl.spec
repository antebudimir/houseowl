Name:    houseowl
Release: 1%{?dist}
Summary: HouseOwl helps you organize your household
License: Apache 2.0
Source0: houseowl
Source1: houseowl.desktop
Requires: libsecret

%description
HouseOwl helps you organize your household.

%install
mkdir -p %{buildroot}%{_datadir}/houseowl
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_bindir}
cp -R %{SOURCE0} %{buildroot}%{_datadir}
chmod +x %{buildroot}%{_datadir}/houseowl/houseowl
ln -s %{_datadir}/houseowl/houseowl %{buildroot}%{_bindir}
install -p -m 755 %{SOURCE1} %{buildroot}%{_datadir}/applications

%files
%defattr(-,root,root)
%dir %{_datadir}/houseowl
%{_datadir}/applications/houseowl.desktop
%{_datadir}/houseowl
%{_bindir}/houseowl

%clean
rm -rf %{buildroot}

%changelog
* Tue Mar 30 2021 Tom Bursch <tombursch@gmail.com> - 22
- Initial Release


Name:           auto-app
Version:        0.1
Release:        1%{?dist}
Summary:        Sample auto apps

License:        MIT
Source0:        auto-app-%{version}.tar.gz

BuildRequires:  cmake make gcc-c++

%description
Sample placeholder application for AutoSD

%prep
%autosetup

%build
%cmake
%cmake_build

%install
%cmake_install

%files
%{_bindir}/auto-app

%changelog
* Thu Jul 10 2026 Michael Kuehl <mkuehl@redhat.com>
- Placeholder hello-world app

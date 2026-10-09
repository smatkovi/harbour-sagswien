Name:       harbour-sagswien
Summary:    Meldungen an die Stadt Wien
Version:    0.2.1
Release:    1
Group:      Qt/Qt
License:    GPLv3+
URL:        https://github.com/smatkovi/harbour-sagswien
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-sagswien.yaml

Requires:   sailfishsilica-qt5 >= 0.10.9
# Der Ortungsempfaenger liegt im positioning-Import; ohne ihn bleibt die
# Naheliste leer und die neue Meldung ohne Ort.
Requires:   qt5-qtdeclarative-import-positioning

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Gui)
BuildRequires:  pkgconfig(Qt5Positioning)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  desktop-file-utils

%description
Ein eigener Client fuer den Meldungsdienst "Sag's Wien" der Stadt Wien.
Zeigt die Meldungen in der Naehe, alle Meldungen und die eigenen, mit
Fotos, Stand der Bearbeitung und den Antworten der Stadt, und gibt neue
Meldungen mit Ort und Foto auf. Die Karte zeichnet Rasterkacheln von
basemap.at.

Weder von der Stadt Wien noch vom Magistrat herausgegeben oder unterstuetzt.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 VERSION=%{version}
%make_build

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Thu Oct 09 2026 smatkovi <sebastian.matkovich@gmail.com> 0.2.1-1
- Bildwaehler auf Sailfish: MediaIndexing fehlte in den Berechtigungen,
  die Seite blieb schwarz.

* Thu Oct 09 2026 smatkovi <sebastian.matkovich@gmail.com> 0.2.0-1
- Kommentieren: der Dienst braucht dafuer keinen Schluessel.
- Auf dem N950 nachgemessen: Anmeldung, Meldungen, Fotos und Kacheln.

* Thu Oct 09 2026 smatkovi <sebastian.matkovich@gmail.com> 0.1.0-1
- Erste Fassung: Meldungen lesen, Karte, neue Meldung mit Ort und Foto.

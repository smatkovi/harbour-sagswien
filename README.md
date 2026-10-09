# Sag's Wien für Sailfish OS und MeeGo Harmattan

Ein eigener Client für den Meldungsdienst **Sag's Wien** der Stadt Wien —
für das Jolla und für das Nokia N9/N950.

> Weder von der Stadt Wien noch vom Magistrat herausgegeben oder
> unterstützt. Die Marke und das Startsymbol gehören der Stadt Wien.

![Startsymbol](icons/172x172/harbour-sagswien.png)

## Was er kann

* Meldungen ansehen: alle, die in der Nähe, die eigenen — mit Fotos,
  Stand der Bearbeitung (Neu, In Bearbeitung, Erledigt) und den
  Antworten der Stadt
* Karte mit Rasterkacheln von basemap.at, Stadtplan oder Luftbild
* Eine neue Meldung aufgeben: Kategorie, Text, Ort (Satellit, Adresse
  oder auf der Karte gewählt) und Fotos aus der Galerie
* Mitreden: einen Kommentar an eine Meldung schreiben

## Pakete

Drei Stück, alle am Release:

| Datei | Für |
|---|---|
| `harbour-sagswien-<v>-1.aarch64.rpm` | Sailfish OS, 64 Bit |
| `harbour-sagswien-<v>-1.armv7hl.rpm` | Sailfish OS, 32 Bit |
| `harbour-sagswien_<v>-meego1_armel.deb` | MeeGo Harmattan (N9/N950) |

Auf Harmattan **mit `aegis-dpkg -i`** installieren, nicht mit `dpkg -i`:
sonst bekommt die Anwendung keinen Platz im Startbildschirm und die
Ortung keine Freigabe.

## Wie er gebaut ist

Ein Quellbaum, zwei Oberflächen. `src/` ist der gemeinsame Kern (Netz,
JSON, API, Bilder, Ortung, Texte); darüber liegen `qml/` mit Silica und
`meego/qml/` mit `com.nokia.meego`.

    tools/build-rpms.sh        beide Sailfish-RPMs (SDK-Container auf arch)
    meego/remote-build.sh      das Harmattan-.deb (Cross-GCC + MADDE)
    tools/make-icons.py        die Startsymbole beider Systeme
    tools/qml-laden.sh         lädt jede Silica-Seite (auf dem Gerät)
    meego/tests/check-qml.sh   liest jede MeeGo-Seite mit Qt 4 ein
    meego/tests/seiten-laden.sh  legt jede MeeGo-Seite **am N9/N950** an
    tests/run.sh               prüft den Meldungskörper, ohne ihn zu senden

Die beiden MeeGo-Prüfer ergänzen einander und ersetzen sich nicht:
`check-qml.sh` läuft auf dem Baurechner, hat `com.nokia.meego` aber nicht
und blendet darum alle „is not a type"-Fehler aus — also genau die, die
eine Eigenschaft betreffen, die es in dieser Fassung der Bibliothek nicht
gibt. `seiten-laden.sh` legt jede Seite auf dem Gerät wirklich an und
findet den Rest. Es hat prompt eins gefunden: `Switch` hat dort kein
`clicked`, und ein `onClicked` daran ließ die Einstellungsseite gar nicht
mehr aufgehen.

### Drei Dinge, die nicht offensichtlich sind

**Auf dem N9 holt ein eigenes Programm die Daten.** Qt 4.7 dort sitzt auf
einem OpenSSL von 2011; `stp.wien.gv.at` lehnt TLS 1.0 und 1.1 ab. Die
Anfragen gehen deshalb durch `sagswien-fetch` (Rust, rustls, statisch
gegen musl) — dieselbe Lösung wie bei Pass Viewer. Auf Sailfish genügt
das System-Qt.

**Der Bildwähler auf dem N9 geht nicht über die Galerie.** QtMobilitys
`DocumentGalleryModel` liefert dort als gewöhnlicher Benutzer null
Treffer: es liest den Tracker-Index unmittelbar aus `~/.cache/tracker`,
und das Verzeichnis gehört der Gruppe `metadata-users` — der Eigentümer
selbst hat keine Rechte darauf. Sich die Gruppe im aegis-Manifest zu
holen, nützt nichts (ein selbstgebautes Paket bekommt sie nicht).
Der Wähler geht deshalb über `Qt.labs.folderlistmodel` direkt durch die
Bilderordner.

**Es gibt keinen Testserver.** `PUT Meldung` legt eine echte Beschwerde
beim Magistrat an, und ein Kommentar steht öffentlich an einer fremden
Meldung. Beide Wege werden beim Entwickeln nie abgeschickt; geprüft
werden sie über `Api::buildReport` und `Api::buildComment` in
`tests/bodytest.cpp`, das dieselben Körper baut und nur ihre Form
kontrolliert.

**Kommentieren braucht keinen Schlüssel.** Die Schnittstelle der
Original-App führt einen Kopf `ApiKey`, aber die einzige Aufrufstelle
übergibt dafür `null` — Retrofit lässt den Kopf dann ganz weg. Am Dienst
nachgemessen: ohne jeden Kopf antwortet er auf einen kaputten Körper mit
HTTP 400, nicht mit 401 oder 403.

## Woher die Kenntnis stammt

Aus der Android-App 4.0.8 ausgelesen und am Dienst selbst nachgemessen.
**`doc/BEFUND.md`** führt jeden Punkt und sagt dazu, was belegt und was
vermutet ist — Endpunkte, Datenmodell, die Statuszahlen, die Fallen
(Aufzählungen sind Zahlen, `Kategorien` mit großem K) und die Messung
der TLS-Lage.

## Daten und Lizenzen

* Meldungen: `stp.wien.gv.at` (Stadt Wien)
* Adressen: `data.wien.gv.at`, Open Government Data
* Karten: basemap.at / Stadt Wien, CC BY 4.0
* Dieses Programm: GNU GPL, Version 3 oder später

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
    tests/run.sh               prüft den Meldungskörper, ohne ihn zu senden

### Zwei Dinge, die nicht offensichtlich sind

**Auf dem N9 holt ein eigenes Programm die Daten.** Qt 4.7 dort sitzt auf
einem OpenSSL von 2011; `stp.wien.gv.at` lehnt TLS 1.0 und 1.1 ab. Die
Anfragen gehen deshalb durch `sagswien-fetch` (Rust, rustls, statisch
gegen musl) — dieselbe Lösung wie bei Pass Viewer. Auf Sailfish genügt
das System-Qt.

**Es gibt keinen Testserver.** `PUT Meldung` legt eine echte Beschwerde
beim Magistrat an. Beim Entwickeln wird dieser Weg nie abgeschickt;
geprüft wird er über `Api::buildReport` in `tests/bodytest.cpp`, das
denselben Körper baut und nur seine Form kontrolliert.

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

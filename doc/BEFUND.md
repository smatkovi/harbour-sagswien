# Sag's Wien — Vorbefund (09.10.2026)

Quelle: `~/Downloads/Sag's+Wien_4.0.8_APKPure.apk` (69 MB, versionCode 211,
Paket `at.gv.wien.sagswien.app.droid`, minSdk 30, targetSdk 36).
Zerlegt auf arch: `/tmp/sagswien/src` (jadx 1.5.6, 7597 Klassen, 125 Fehler).
**Liegt in /tmp — vor dem Weiterarbeiten `find /tmp/sagswien -exec touch {} +`.**

## 1. Die APK ist die Quelle, nicht der Portierkandidat

Compose Multiplatform + Kotlin, R8 mit voller Umbenennung (alles in
`defpackage/`, 6443 Klassen). Native Teile: nur `libmaplibre.so` (11-15 MB,
alle vier ABIs) und zwei androidx-Stummel. Haengt an Firebase (Crashlytics,
Messaging, Remote Config) und Play Core.

Also derselbe Fall wie WienMobil und ÖBB Tickets: **eigener Qt-Client gegen
die API**, kein apkenv.

## 2. Kein Attestierungs-Wall — und die API ist offen

Gesucht und **nicht gefunden**: Play Integrity, SafetyNet, reCAPTCHA,
Turnstile, hCaptcha, DeviceCheck, Attestation. Kein `CertificatePinner`.
Der einzige OkHttp-Interceptor (`x32`) ist der Logging-Interceptor.
Kein globaler API-Schluessel — nur `Kommentar` nimmt einen `ApiKey`-Header.

**Live geprueft (09.10.2026):** `GET Kategorie/All` antwortet ohne jeden
Header mit HTTP 200 und sechs Kategorien.

## 3. Grundadresse und Endpunkte

Grundadresse (aus `iv.java`, Retrofit-Basis "RetrofitSagsWien"):

    https://stp.wien.gv.at/sagswienWeb2025/

Nebenstellen:

    https://stp.wien.gv.at/SagsWien-tileserver/data/output.json   Karten-Kacheln
    https://stp.wien.gv.at/SagsWien-reportpinlayerserver/report/  Pin-Ebene
    https://data.wien.gv.at/daten/OGDAddressService.svc/          Adressen (OGD)
    https://mtk.wien.gv.at/styles/wien/stadtplan.json             Stadtplan-Stil

Die Annotationen sind verschleiert, aufgeloest aus `c42.java:569-578`:
`@yu1`=GET, `@po3`=POST, `@qo3`=PUT, `@ux`=Body, `@t54`=Query,
`@zr3`=Path, `@pz1`=Header.

| Methode | Pfad | Koerper | Antwort |
|---|---|---|---|
| GET  | `Kategorie/All` | — | `List<KategorieDTO>` |
| POST | `Meldung/Filtered` | `MeldungKriterienDTO` | `List<MeldungDto>` |
| POST | `Meldung/GetById` | `MeldungDto` | `MeldungDto` |
| PUT  | `Meldung` | `MeldungDto` | `MeldungDto` |
| PUT  | `Meldung/Subscribe` | `UeserMeldungInfoDTO` | `Boolean` |
| PUT  | `Kommentar?type=…` | `KommentarDTO` (Header `ApiKey`) | `KommentarDTO` |
| POST | `Profile/UpdateData` | `ProfileDTO` | `ProfileDTO` |
| GET  | `Geraet/{id}` | — | `GeraeteInfoDTO` |
| PUT  | `Geraet` | `GeraeteInfoDTO` | `GeraeteInfoDTO` |
| GET  | `ReverseGeocode?location=&crs=` | — | (OGD) |
| GET  | `GetAddressInfo?Address=&crs=` | — | (OGD) |

**Eine Meldung anlegen ist ein `PUT Meldung`** — kein Mehrteilen, kein
Vorab-Upload.

## 4. Datenmodell (Feldnamen aus den toString-Methoden)

`MeldungDto` (`j23`): meldungId, status, adresse, tsMeldung, geraetInfoId,
appVersion, meldungsText, kategorieIds, kategorien, images, kommentare,
profile, liked, subscribed, anzahlLikes, anzahlSubscriptions, abstand,
istInAmtszeit, alleDuerfenKommentieren, istSubmelder, alleBilderLesbar,
istMelder, uniqueId, provider, providerMeldungsUrl, archiviert, feedbackDto.
Pflicht beim Lesen (Maske 15): meldungId, status, adresse, tsMeldung.

`AdressDTO` (`g6`): geraetInfoId, appVersion, latitude, longitude,
rechtswert, hochwert, plz, ort, strasse, hausnummer, acd, scd, bezirk,
adresse.

`ImageDTO` (`l52`): geraetInfoId, appVersion, **rawImage**, url, imageId,
aufnahmedatum, aufloesung, hoehe, breite, logischGeloescht, folderName.
Neu angelegte Bilder tragen `imageId = 00000000-0000-0000-0000-000000000000`
und das Bild selbst in `rawImage` — **Fotos gehen als Base64 im JSON der
Meldung mit**, kein eigener Upload-Endpunkt.

`GeraeteInfoDTO` (`bx1`): geraetInfoId, appVersion, hardwareId,
isHardwareIdKnown, cultureName, osPlatform (Aufzaehlung 0/1/2, die App
schickt 0), model, osVersion (`GeraetInfoVersionDTO`: major, minor, build,
revision), token, profileId, profile, authToken.
Alle Felder sind beim Lesen wahlfrei (Maske 0).

`MeldungKriterienDTO` (`m23`, der Filter): geraetInfoId (**Pflicht**,
Maske 1), appVersion, kriterienName, kriterienId, eigeneMeldungen,
meldungVon, meldungBis, maximaleTage, maximaleAnzahl, kategorien,
inNaeheAdresse, alleOffenenAusserhalbZeitraum, distanz, adresseRequired,
alleLiked, alleSubscribed, keineEigeneMeldungen, sortierung, profileId,
unterdrueckeGeloeschteMeldungen, unterdrueckeErledigteMeldungen,
istBenutzerdefiniertesKriterien, minRow, maxRow,
excludeExternalProviderMessages, unterdrueckeArchivierte.

`ProfileDTO` (`r14`): profileId, geraetInfoId, appVersion, email, nickname,
nachname, vorname, anrede, image, type, subscribeToNewsletter,
stadtWienKontoId.

`KommentarDTO` (`qh2`): meldungId, kommentarText, erzeugtAm, geraetInfoId,
appVersion, meldung, profile, istRedaktion, geloescht, noPushSend, images.

`FeedbackDto` (`di1`): meldungId, geraetInfoId, appVersion,
feedbackAllgemein, feedbackErledigung, feedbackInformationsgehalt.

`UeserMeldungInfoDTO` (`bo5`): geraetInfoId, meldungId, wert, appVersion.

## 5. Es gibt keine Anmeldung — es gibt eine Geraetekennung

Kein OAuth, kein Keycloak, kein Passwort-Grant. Die Sitzung ist die
`geraetInfoId`.

**Live durchgespielt (09.10.2026).** `PUT Geraet` mit

    {"hardwareId":"<uuid>","isHardwareIdKnown":true,"cultureName":"de-AT",
     "osPlatform":0,"model":"Nokia N9",
     "osVersion":{"major":1,"minor":3,"build":0,"revision":0},
     "appVersion":"0.1.0"}

antwortet mit HTTP 200 und legt ein Gastprofil an:

    geraetInfoId = 334d5f59-a196-4804-966a-37b727cef7d9
    profileId    = ef02c3d0-5967-4842-9c2b-1b5315b240af
    nickname     = "Gast 246349"
    authToken    = null      <- es gibt keinen
    token        = null      <- Push, brauchen wir nicht

Also: **einmal registrieren, Kennung wegspeichern, fertig.** Sie ist der
einzige Ausweis, sie geht in jeden Koerper. `hardwareId` und `model` kommen
leer zurueck — der Server behaelt sie nicht.

## 6. Die Aufzaehlungen sind Zahlen, keine Zeichenketten

Die wichtigste Falle, und sie hat beim ersten Versuch zugeschlagen. Die App
deklariert die Serialnamen als `"0"`, `"1"`, `"2"` (aus `y15.java`,
`g03.w("…SortierungType", …, {"0","1","2"})`), also schreibt kotlinx sie als
JSON-**Zeichenketten**. Der Server ist aber ASP.NET Core und nimmt nur die
nackte Zahl:

    "osPlatform":"0"  ->  HTTP 400
        The JSON value could not be converted to
        SagsWien.Common.Enums.OSPlatformen
    "osPlatform":0    ->  HTTP 200

Betrifft `osPlatform` (OSPlatformen 0/1/2), `status` (StatusTypen 0/2/4/8),
`sortierung` (SortierungType 0/1/2) und `type` (BenutzerTypen).
Angenehm dabei: der Server meldet Feldfehler einzeln und im Klartext —
beim Entwickeln ist das Gold wert. Ein kaputter Koerper zieht ausserdem
immer ein zweites, irrefuehrendes
`"geraeteInfoDTO": ["The geraeteInfoDTO field is required."]` nach sich
(Bindung schlug fehl, Parameter blieb leer) — **der Koerper ist nicht
umhuellt**, nicht darauf hereinfallen.

## 7. Meldungen lesen — live geprueft

`POST Meldung/Filtered` mit

    {"geraetInfoId":"<kennung>","appVersion":"0.1.0","maximaleAnzahl":5,
     "maximaleTage":30,"sortierung":0,"unterdrueckeGeloeschteMeldungen":true,
     "unterdrueckeArchivierte":true,"excludeExternalProviderMessages":false,
     "adresseRequired":true}

gibt HTTP 200 und fuenf echte Meldungen. Ohne `geraetInfoId`: HTTP 500.

Drei Abweichungen der echten Antwort vom Modell der App:

- Die Kategorienliste heisst in der Antwort **`Kategorien`** mit grossem K,
  nicht `kategorien`. Ein Deuter, der auf Kleinschreibung besteht, sieht
  nie eine Kategorie.
- Es kommen Felder, die die App nicht kennt: `anzahlKommentar`,
  `instanceId`.
- Die `kategorieId` in der Meldung liegt in einem **anderen Zahlenraum** als
  die aus `Kategorie/All` ("Straßen & Baustellen" ist dort
  `64fe802d-…`, in der Meldung `01d150e7-…`). Zum Anzeigen taugt die
  `bezeichnung` aus der Meldung selbst; zum Anlegen die Kennung aus
  `Kategorie/All`.

`adresse` ist gut gefuellt: latitude, longitude, plz, ort, strasse,
hausnummer, scd, adresse ("Sturzgasse 6A").

**Die Statuszahlen sind belegt** (`oc4.java:59-66`, dieselben Ordinalzahlen
wie `StatusTypen` in `p45.java`):

    0  Neu
    2  In Bearbeitung
    4  Erledigt
    8  Geloescht

Und die Adressdienste der Stadt passen eins zu eins auf das `AdressDTO`:
`ReverseGeocode` und `GetAddressInfo` liefern dasselbe GeoJSON mit
`StreetName`, `StreetNumber`, `PostalCode`, `Municipality`, `Adresse`,
`ACD`, `SCD`, `Bezirk` — und die `SCD` "04798" der Probe-Meldung ist genau
die der Sturzgasse 6A. `plz` ist im Meldungsmodell eine **Zahl** (1150),
im Adressdienst eine Zeichenkette.

## 8. Bilder: zwei Wege, beide einfach

**Holen** (live geprueft): die Meldung liefert `url` als relativen Pfad
`images/BySize/<imageId>/`. Daran haengt die Breite:

    GET {Grundadresse}images/BySize/<imageId>/        -> 480 KB JPEG (voll)
    GET {Grundadresse}images/BySize/<imageId>/400     ->  24 KB JPEG

Fuer ein 480-Pixel-Telefon ist das genau richtig — nie das Volle holen.

**Schicken**: als `rawImage` (Base64) im `images`-Feld der Meldung, mit
`imageId = 00000000-0000-0000-0000-000000000000`. Kein eigener
Upload-Endpunkt, kein Mehrteilen.

## 9. TLS: der N9 kommt nicht allein hin

Gemessen am 09.10.2026:

    stp.wien.gv.at   TLS 1.0/1.1 abgelehnt, 1.2 ECDHE-RSA-AES256-GCM-SHA384,
                     1.3 TLS_CHACHA20_POLY1305_SHA256
    data.wien.gv.at  dasselbe Bild
    Kette            Sectigo Public Server Authentication CA OV R36

Harmattans Qt 4.7 bringt OpenSSL 0.9.8 und damit nur TLS 1.0 — es kommt
**gar nicht** hin. Also derselbe Weg wie bei Pass Viewer und Fluesterwind:
ein Rust-Holer mit rustls als eigenes Programm, die Oberflaeche spricht
ueber QProcess mit ihm. Siehe `harmattan-tls-stacks`.
Auf Sailfish (Qt 5) reicht das System-OpenSSL.

## 10. Karte: MapLibre faellt weg, Rasterkacheln gibt es

Die App zeichnet Vektorkacheln mit `libmaplibre.so` (11-15 MB) —
auf keinem der beiden Zielsysteme zu haben. Aber die Stadt Wien liefert
dieselbe Gegend als Rasterkacheln (live geprueft):

    https://mapsneu.wien.gv.at/basemap/geolandbasemap/normal/
        google3857/{z}/{y}/{x}.png        -> 256x256 PNG, 60 KB
    .../bmaporthofoto30cm/normal/google3857/{z}/{y}/{x}.jpeg  (Luftbild)

Die Kachelordnung ist **`{z}/{y}/{x}`**, Zeile vor Spalte — nicht wie bei
OSM. Nachgemessen: der Stephansdom liegt bei z14 auf x=8937, y=5681, und
nur `/14/5681/8937.png` antwortet mit 200; vertauscht gibt es 404.
Wer das verwechselt, bekommt eine Karte, die stimmt, solange man auf der
Diagonale bleibt. Ausserhalb Oesterreichs antwortet der Server mit 404 —
der Kachelspeicher muss das aushalten, ohne in eine Schleife zu laufen.

Und: der Kachelserver spricht **kein http** (301 auf https), es gibt also
auch hier keinen Umweg um TLS. Auf Harmattan muessen die Kacheln durch
denselben Holer wie alles andere.

## 11. Kein Testserver — Regel fuer die Bauzeit

Gesucht und nicht gefunden: kein `stp-test`, kein `stage`, kein `-dev`.
Es gibt **nur die Produktion**. Daraus folgt eine harte Regel:

**`PUT Meldung`, `PUT Kommentar`, `PUT Meldung/Subscribe` und
`POST Profile/UpdateData` werden beim Entwickeln nicht abgeschickt.**
Eine Probemeldung ist eine echte Beschwerde beim Magistrat und bindet
Arbeitszeit von Menschen. Der Anlege-Weg wird gebaut und sein JSON gegen
die Form der App geprueft; zum ersten Mal abgeschickt wird er erst, wenn
der Nutzer absichtlich etwas Echtes melden will. Lesen (`Kategorie/All`,
`Meldung/Filtered`, `Meldung/GetById`, Bilder) ist frei.

## 11a. Kommentieren braucht keinen Schluessel

Die Schnittstelle der App fuehrt einen Kopf `ApiKey`:

    @qo3("Kommentar")
    Object a(@pz1("ApiKey") String str, @t54("type") String str2, ...)

In den Ressourcen steht kein Schluessel (`res/values/*` durchsucht, nichts).
Der Grund ist einfacher: **es gibt genau eine Aufrufstelle, und die
uebergibt `null`** (`v8.java:268`):

    ((nh2) ie4Var.a).a(null, "", qh2Var, this);

Retrofit laesst einen Kopf mit null-Wert ganz weg -- der Kopf wird also nie
geschickt. Die Abfrage `type` steht leer.

**Am Dienst nachgemessen (09.10.2026):** `PUT Kommentar?type=` ohne jeden
Kopf, mit einer absichtlich ungueltigen Kennung im Koerper, antwortet mit
**HTTP 400** -- nicht 401 und nicht 403. Es gibt also keine Sperre, nur die
Modellpruefung. (Der Koerper war bewusst kaputt, damit nichts angelegt wird.)

`KommentarDTO` beim Schreiben: meldungId, kommentarText, erzeugtAm,
geraetInfoId, appVersion, istRedaktion (**ausdruecklich false** -- true
hiesse, sich als die Behoerde auszugeben), geloescht false, noPushSend
false. Fuer Kommentare gilt dieselbe Regel wie fuer Meldungen: sie stehen
oeffentlich an einer fremden Meldung, also nicht beim Entwickeln
abschicken.

## 11b. Am N950 nachgemessen (09.10.2026)

Das Paket `0.2.0-meego1` mit `aegis-dpkg -i` installiert und gelaufen:

    PUT  Geraet            -> 200, geraetInfoId 465cf872-...  ("Gast 246353")
    GET  Kategorie/All     -> 200
    POST Meldung/Filtered  -> 200, 8357 B, Status 0 und 4
    GET  images/BySize/.../400 -> 200, 15 493 B, beginnt mit ff d8 ff
    GET  basemap-Kachel    -> 200, 98 909 B

Damit sind der Rust-Holer, TLS 1.2 ab Harmattan, die Zahlen-Aufzaehlungen
und die Statuszuordnung **am Geraet** belegt, nicht nur am Schreibtisch.

Zwei Fallen beim Pruefen auf dem Geraet, beide gekostet:

- **`pgrep -x harbour-sagswien` trifft nie.** Linux kuerzt `comm` auf 15
  Zeichen, der Name hat 16 -- also `pkill -x harbour-sagswie`. Und
  `pkill -f` ist hier keine Alternative: es trifft die eigene ssh-Shell
  mit (siehe `pkill-killt-die-shell`).
- **In `control.in` duerfen keine `#`-Kommentare stehen.** Debian-control
  kennt keine, und es faellt erst beim Installieren auf dem Geraet auf
  ("field name `#` must be followed by colon"), nicht beim Bauen.

Und ein Fehler, den nur das Geraet zeigen konnte: **`Switch` in
com.nokia.meego hat kein `clicked`-Signal.** Ein `onClicked` daran liess
die ganze Einstellungsseite nicht mehr aufgehen. Der Pruefer auf dem
Baurechner kann das strukturell nicht finden -- ihm fehlt
com.nokia.meego, deshalb blendet er alle "is not a type"-Fehler aus, also
genau diese Klasse. Dafuer gibt es jetzt `meego/tests/seiten-laden.sh`:
es schiebt eine Sonde als `main.qml` unter, laesst die App jede Seite
anlegen und legt danach zurueck.

Nebenbei beantwortet: das QML-Plugin des Bildwaehlers liegt in
`/usr/lib/qt4/imports/QtMobility/gallery` und kommt aus **`libqtm-gallery`**
(mit `dpkg -S` nachgesehen) -- es ist ab Werk da.

## 12. Nicht noetig fuer das Ziel

Firebase (Crashlytics, Remote Config, Push), Play Core (In-App-Review),
`SagsWien-reportpinlayerserver` (Pin-Ebene der Vektorkarte), Newsletter,
Stadt-Wien-Konto, `stadtWienKontoId`.

## 13. Fuer die Bauphase vorgemerkt

- Baum nach dem Muster `harbour-radelt`: ein Quellbaum, `rpm/` fuer SFOS,
  `meego/` fuer Harmattan, drei Pakete (aarch64, armv7hl, armel-deb)
- Icon: Squircle-Maske nach `meego-squircle-icons`, Vorlage
  `~/ps/harbour-passviewer/meego/icons/make-icon.py`.
  **Das Launcher-Icon liegt noch nicht vor** — jadx lief mit `--no-res`,
  also `res/mipmap-*` aus der APK auspacken.
- Oberflaeche MeeGo: Qt 4.7 / com.nokia.meego, Fallen nach
  `harmattan-qml-ui-fallen`
- Ortung auf Harmattan braucht das `Location`-Token im `_aegis`
  (`meego-ortung-location-token`); Installieren mit `aegis-dpkg -i`
- SFOS: `OrganizationName = ApplicationName = harbour-sagswien` in main.cpp
  **und** im `[X-Sailjail]`-Block (`sailfish-settings-sandbox`),
  Kennung in `AppDataLocation`
- SFOS-Berechtigungen: `Internet;Location;Pictures;MediaIndexing`.
  **MediaIndexing ist nicht optional**, sobald ein Bildwaehler dabei ist:
  `Pictures` gibt nur den Dateizugriff, aber `ImagePickerPage` listet
  ueber `QtDocGallery`/`DocumentGalleryModel`, und das redet per D-Bus mit
  Tracker3 -- freigegeben allein von `MediaIndexing`
  (`dbus-user.talk org.freedesktop.Tracker3.Miner.Files`). Ohne sie bleibt
  die Seite schwarz, ohne Fehlermeldung. Gegenprobe: jede installierte App
  mit diesem Waehler fuehrt sie (Whisperfish, SeaPrint, Fernschreiber,
  RooTelegram), unsere war die einzige ohne.
  Liegen Fotos auf der Speicherkarte, braucht es zusaetzlich
  **`RemovableMedia`**: das hebt firejails `disable-mnt` auf (sonst ist
  `/run/media/<nutzer>` im Sandkasten schlicht nicht da) und horcht per
  UDisks mit, wann eine Karte kommt und geht. Die Endfassung ist damit
  `Internet;Location;Pictures;MediaIndexing;RemovableMedia`.
  Was `Pictures` schon abdeckt und wofuer man **kein** RemovableMedia
  braucht: `~/Pictures` **und** `~/android_storage/Pictures` sowie
  `~/android_storage/DCIM` stehen dort ausdruecklich in der Weissliste.
- Der `ApiKey` fuer `Kommentar` ist noch unbekannt (in `res/values`?) —
  wird erst gebraucht, wenn Kommentieren dazukommt

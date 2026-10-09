#!/bin/sh
# Veroeffentlicht die Pakete einer Fassung als Release dieses Repos.
#
#   tools/release.sh <fassung> <paket> [<paket> ...]
#
# Jede Paketdatei geht: die beiden Sailfish-RPMs und das Harmattan-.deb.
# Noch einmal aufgerufen, haengt es weitere Dateien an das schon
# bestehende Release.
#
# gh ist auf dem Arch-Rechner angemeldet, nicht hier -- die Dateien gehen
# also zuerst dorthin. Eine Kopie landet in ~/ps/rpms/sagswien/, wie es
# die anderen Apps auch halten.
set -e
VERSION=$1
shift 2>/dev/null || true
if [ -z "$VERSION" ] || [ $# -eq 0 ]; then
    echo "Aufruf: tools/release.sh <fassung> <paket> [<paket> ...]" >&2
    exit 2
fi
for FILE in "$@"; do
    [ -f "$FILE" ] || { echo "keine solche Datei: $FILE" >&2; exit 2; }
done

if [ -n "$BUILD_HOST" ]; then
    HOST=$BUILD_HOST
elif ssh -o BatchMode=yes -o ConnectTimeout=4 sebastian@192.168.1.21 true 2>/dev/null; then
    HOST=sebastian@192.168.1.21
else
    HOST=arch
fi
REPO=${REPO:-smatkovi/harbour-sagswien}
TAG=v$VERSION
WORK=/tmp/sagswien-release

mkdir -p "$HOME/ps/rpms/sagswien"
for FILE in "$@"; do
    DEST="$HOME/ps/rpms/sagswien/$(basename "$FILE")"
    if [ "$(readlink -f "$FILE")" != "$(readlink -f "$DEST")" ]; then
        cp "$FILE" "$DEST"
    fi
done

NOTES=$(mktemp)
cat > "$NOTES" <<NOTE
Sag's Wien $VERSION — Meldungen an die Stadt Wien.

Drei Pakete:

| Datei | Fuer |
|---|---|
| \`...aarch64.rpm\` | Sailfish OS, 64 Bit |
| \`...armv7hl.rpm\` | Sailfish OS, 32 Bit |
| \`..._armel.deb\` | MeeGo Harmattan (Nokia N9/N950) |

Auf Harmattan **mit \`aegis-dpkg -i\`** installieren, nicht mit \`dpkg -i\`:
sonst bekommt die Anwendung keinen Platz im Startbildschirm und die
Ortung keine Freigabe.

Meldungen ansehen (alle, in der Naehe, eigene) mit Fotos, Stand der
Bearbeitung und den Antworten der Stadt; Karte von basemap.at; neue
Meldung mit Ort und Fotos aufgeben.

Weder von der Stadt Wien noch vom Magistrat herausgegeben oder
unterstuetzt. Karten: basemap.at / Stadt Wien, CC BY 4.0.
NOTE

ssh "$HOST" "rm -rf $WORK && mkdir -p $WORK"
scp "$@" "$NOTES" "$HOST:$WORK/"
NOTENAME=$(basename "$NOTES")
rm -f "$NOTES"

# Genau die uebergebenen Dateien -- ein Glob hier wuerde stillschweigend
# das .deb weglassen und nur die RPMs hochladen.
NAMES=""
for FILE in "$@"; do
    NAMES="$NAMES $(basename "$FILE")"
done

ssh "$HOST" "cd $WORK && \
    if gh release view $TAG --repo $REPO >/dev/null 2>&1; then \
        gh release upload $TAG$NAMES --repo $REPO --clobber; \
    else \
        gh release create $TAG$NAMES --repo $REPO --title \"Sag's Wien $VERSION\" --notes-file $NOTENAME; \
    fi"
echo "$TAG nach $REPO veroeffentlicht, Kopie in ~/ps/rpms/sagswien/"

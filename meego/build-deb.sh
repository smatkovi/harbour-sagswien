#!/bin/sh
# Packs the ARM build as a Harmattan .deb. Runs on the build machine after
# "meego/build.sh arm" and "meego/build-rust.sh":
#
#   meego/build-deb.sh            -> build/meego/harbour-sagswien_<version>_armel.deb
#   VERSION=0.1.0-meego2 meego/build-deb.sh
#
# Layout on the device:
#   /opt/harbour-sagswien/bin/harbour-sagswien
#   /opt/harbour-sagswien/bin/sagswien-fetch        (HTTPS, see meego/fetch)
#   /opt/harbour-sagswien/qml
#   /opt/harbour-sagswien/translations
#   /usr/share/applications/harbour-sagswien.desktop
#   /usr/share/icons/hicolor/80x80/apps/harbour-sagswien.png
#
# mkdeb.py writes the .deb itself: Harmattan's dpkg is 1.15 and wants gzip
# members and no slash on the ar names, which GNU ar does differently. It
# also appends the aegis manifest as the fourth ar member -- without it the
# application gets no position on the device.
set -e

HERE=$(cd "$(dirname "$0")/.." && pwd)
PKG=$HERE/meego
OUT=$HERE/build/meego
BIN=$OUT/arm/harbour-sagswien
XGCC=${XGCC:-/tmp/xgcc-harmattan}
VERSION=${VERSION:-$(sh "$PKG/version.sh")}

[ -x "$BIN" ] || { echo "ARM binary missing: $BIN (run meego/build.sh arm first)" >&2; exit 1; }
FETCH=$OUT/fetch/sagswien-fetch
[ -x "$FETCH" ] || { echo "sagswien-fetch missing: $FETCH (run meego/build-rust.sh first)" >&2; exit 1; }

STAGE=$OUT/stage
rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$STAGE/opt/harbour-sagswien/bin" \
         "$STAGE/usr/share/applications" "$STAGE/usr/share/icons/hicolor/80x80/apps" \
         "$STAGE/usr/share/themes/base/meegotouch/icons" \
         "$STAGE/usr/share/doc/harbour-sagswien"

cp "$BIN" "$STAGE/opt/harbour-sagswien/bin/harbour-sagswien"
"$XGCC/bin/arm-none-linux-gnueabi-strip" "$STAGE/opt/harbour-sagswien/bin/harbour-sagswien"
cp "$FETCH" "$STAGE/opt/harbour-sagswien/bin/sagswien-fetch"
chmod 755 "$STAGE/opt/harbour-sagswien/bin/harbour-sagswien" \
          "$STAGE/opt/harbour-sagswien/bin/sagswien-fetch"

cp -a "$PKG/qml" "$STAGE/opt/harbour-sagswien/qml"
if [ -d "$OUT/arm/translations" ]; then
    cp -a "$OUT/arm/translations" "$STAGE/opt/harbour-sagswien/translations"
fi

# Icons: 80x80 for the launcher, 64x64 base64 for the application manager.
# tools/make-icons.py cuts both to the exact silhouette of the stock apps.
cp "$PKG/icons/icon-80.png" "$STAGE/usr/share/icons/hicolor/80x80/apps/harbour-sagswien.png"
cp "$PKG/icons/icon-80.png" "$STAGE/usr/share/themes/base/meegotouch/icons/harbour-sagswien-80.png"
cp "$PKG/harbour-sagswien.desktop" "$STAGE/usr/share/applications/harbour-sagswien.desktop"
cp "$HERE/LICENSE" "$STAGE/usr/share/doc/harbour-sagswien/copyright"
find "$STAGE" -type f ! -path "*/bin/*" -exec chmod 644 {} +
find "$STAGE" -type d -exec chmod 755 {} +

# control mit dem Symbol; die base64-Zeilen brauchen je ein fuehrendes
# Leerzeichen.
#
# **In control.in duerfen keine #-Kommentare stehen.** Debian-control
# kennt keine, und Harmattans dpkg bricht beim Installieren ab
# ("field name `#' must be followed by colon") -- also erst auf dem
# Geraet, nicht beim Bauen. Anmerkungen gehoeren hierher.
#
# Zu den Abhaengigkeiten: libqtm-gallery steht bewusst **nicht** drin.
# Der Bildwaehler ging urspruenglich ueber QtMobilitys Galerie, liefert
# dort als `user` aber nichts (der Tracker-Index gehoert metadata-users);
# er geht jetzt ueber Qt.labs.folderlistmodel, und das steckt in
# libqt4-declarative.
ICON=$(base64 -w 76 "$PKG/icons/icon-64.png" | sed 's/^/ /')
awk -v version="$VERSION" -v icon="$ICON" '
    { gsub(/@VERSION@/, version) }
    /^@ICON@$/ { print icon; next }
    { print }
' "$PKG/control.in" > "$STAGE/DEBIAN/control"

cp "$PKG/_aegis" "$STAGE/DEBIAN/_aegis"

DEB=$OUT/harbour-sagswien_${VERSION}_armel.deb
python3 "$PKG/mkdeb.py" "$STAGE" "$DEB"
python3 "$PKG/mkdeb.py" --info "$DEB" | head -20

#!/bin/sh
# Baut und laeuft die Tests, die ohne Geraet und ohne Netz auskommen.
#
#   sh tests/run.sh
#
# Laeuft auf dem Telefon selbst (Sailfish, Qt 5): dort stehen Qt und g++
# bereit, und die Tests brauchen weder Silica noch QtPositioning.
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
OUT=$HERE/build/tests
mkdir -p "$OUT"

CFLAGS=$(pkg-config --cflags Qt5Core Qt5Gui Qt5Network)
LIBS=$(pkg-config --libs Qt5Core Qt5Gui Qt5Network)
MOC=$(command -v moc-qt5 || command -v moc || echo /usr/lib/qt5/bin/moc)

# moc braucht die Qt-Header im Suchpfad. Ohne sie kennt es QT_VERSION
# nicht, nimmt in http.h **beide** Zweige des #if mit und erzeugt Code
# fuer NetworkHttp *und* ProcessHttp -- letzterer existiert unter Qt 5
# gar nicht, und das Ergebnis uebersetzt nicht.
for h in api http settings format; do
    "$MOC" $CFLAGS -I"$HERE/src" "$HERE/src/$h.h" -o "$OUT/moc_$h.cpp"
done

g++ -O1 -fPIC -std=gnu++11 -w \
    -DAPP_VERSION='"0.0.0-test"' \
    -I"$HERE/src" $CFLAGS \
    "$HERE/tests/bodytest.cpp" \
    "$HERE/src/api.cpp" "$HERE/src/json.cpp" "$HERE/src/http.cpp" \
    "$HERE/src/settings.cpp" "$HERE/src/format.cpp" \
    "$OUT/moc_api.cpp" "$OUT/moc_http.cpp" \
    "$OUT/moc_settings.cpp" "$OUT/moc_format.cpp" \
    $LIBS -o "$OUT/bodytest"

"$OUT/bodytest"

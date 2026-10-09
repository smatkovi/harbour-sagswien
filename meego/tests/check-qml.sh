#!/bin/sh
# Liest die MeeGo-QML mit Qt 4s QDeclarative auf dem Baurechner ein.
#
#   meego/tests/check-qml.sh
#
# Catches what only shows on the device otherwise: a property that does not
# exist under QtQuick 1.1, a mistyped binding, a file that does not parse.
set -e
HERE=$(cd "$(dirname "$0")/../.." && pwd)
sh "$HERE/meego/build.sh" check
"$HERE/build/meego/check/harbour-sagswien" "$HERE/meego/qml"

#!/bin/sh
# Laedt jede MeeGo-Seite **auf dem Geraet** und sagt, woran eine scheitert.
#
#   N9_HOST=192.168.1.8 sh meego/tests/seiten-laden.sh
#
# Warum zusaetzlich zu meego/tests/check-qml.sh: jener laeuft auf dem
# Baurechner, der com.nokia.meego nicht hat, und blendet deshalb alle
# "is not a type"-Fehler aus -- also genau die Fehler, die eine
# Eigenschaft oder Komponente betreffen, die es in dieser Fassung der
# Bibliothek nicht gibt. Gefunden hat das hier zum Beispiel ein
# onClicked an einem Switch: es gibt dort keins, und die ganze
# Einstellungsseite ging daraufhin nicht mehr auf.
#
# Die Sonde wird als main.qml untergeschoben und danach wieder
# weggenommen; die App bleibt installiert und heil.
set -e
HERE=$(cd "$(dirname "$0")/../.." && pwd)
N9SSH=$HERE/tools/n9ssh.sh
ZIEL=/opt/harbour-sagswien/qml

scp -J "${N9_JUMP:-sebastian@192.168.1.21}" \
    -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa \
    -oStrictHostKeyChecking=accept-new -i "$HOME/.ssh/id_rsa_n9" \
    "$HERE/meego/tests/laden.qml" "user@${N9_HOST:-192.168.1.8}:/tmp/" >/dev/null

# Die App wird im Hintergrund gestartet und nach einer festen Frist
# beendet. Auf Qt.quit() ist kein Verlass -- bei einem PageStackWindow
# bleibt die App schon mal stehen, und dann haengt dieses Skript, waehrend
# auf dem Geraet die Sonde als main.qml liegt. Beendet wird mit dem auf
# 15 Zeichen gekuerzten comm-Namen: "pkill -f" traefe die eigene Shell mit,
# und den vollen 16-Zeichen-Namen sieht comm nie.
sh "$N9SSH" "pkill -x harbour-sagswie 2>/dev/null; sleep 1
sudo cp $ZIEL/main.qml /tmp/main.qml.echt
sudo cp /tmp/laden.qml $ZIEL/main.qml
[ -f /tmp/session_bus_address.user ] && . /tmp/session_bus_address.user && export DBUS_SESSION_BUS_ADDRESS
cd /tmp && (DISPLAY=:0 /opt/harbour-sagswien/bin/harbour-sagswien > /tmp/probe.log 2>&1 &)
sleep 25
pkill -x harbour-sagswie 2>/dev/null
sleep 2
sudo cp /tmp/main.qml.echt $ZIEL/main.qml
echo '--- main.qml zurueckgelegt:'
md5sum $ZIEL/main.qml
grep -E 'FEHLER|PRUEFUNG' /tmp/probe.log"

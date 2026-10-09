#!/bin/sh
# Builds the MeeGo edition on the Arch build machine and fetches the .deb.
#
#   meego/remote-build.sh
#   BUILD_HOST=sebastian@192.168.1.21 meego/remote-build.sh
#
# Everything heavy happens there: the cross toolchain, the MADDE sysroot and
# the Rust musl target live on that machine, and a long build must not hang
# on the phone's ssh session.
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
REMOTE=/tmp/sagswien-meego/src   # nicht /tmp/sagswien: dort liegt der zerlegte APK-Baum,
                                 # und rsync --delete wuerde ihn abraeumen
OUT=${OUT:-$HOME/ps/rpms/sagswien}

if [ -n "$BUILD_HOST" ]; then
    HOST=$BUILD_HOST
elif ssh -o BatchMode=yes -o ConnectTimeout=4 sebastian@192.168.1.21 true 2>/dev/null; then
    HOST=sebastian@192.168.1.21
else
    HOST=arch
fi
echo "Baurechner: $HOST"

ssh "$HOST" "mkdir -p $REMOTE"
# --exclude /build, not --exclude build*: the latter also eats tools/build-*.sh.
rsync -a --partial --delete --exclude .git --exclude /build "$HERE/" "$HOST:$REMOTE/"

ssh "$HOST" "tmux kill-session -t sagswien-meego 2>/dev/null; \
    tmux new-session -d -s sagswien-meego 'cd $REMOTE && \
      { sh meego/build-rust.sh && sh meego/build.sh arm && sh meego/build-deb.sh ; } \
      > /tmp/sagswien-meego.log 2>&1; echo FERTIG_RC=\$? >> /tmp/sagswien-meego.log'"
echo "tmux-Sitzung sagswien-meego laeuft, Log /tmp/sagswien-meego.log"

while ssh "$HOST" "tmux has-session -t sagswien-meego 2>/dev/null"; do
    sleep 20
done
ssh "$HOST" "tail -20 /tmp/sagswien-meego.log"
ssh "$HOST" "grep -q 'FERTIG_RC=0' /tmp/sagswien-meego.log" || { echo "Bau fehlgeschlagen"; exit 1; }

mkdir -p "$OUT"
rsync -a --partial "$HOST:$REMOTE/build/meego/*.deb" "$OUT/"
ls -l "$OUT"/*.deb

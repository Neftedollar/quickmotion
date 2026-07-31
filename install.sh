#!/usr/bin/env bash
# Installs the QuickMotion QML module.
#
#   sudo ./install.sh                 install or update
#   sudo ./install.sh --uninstall     remove it
#   DESTDIR=/tmp/pkg ./install.sh     stage into a package root
#
# Goes into Qt's QML import path, so consumers write `import QuickMotion`
# with no path juggling. Quickshell reads that path like any Qt program.

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

DESTDIR="${DESTDIR:-}"
PREFIX="${PREFIX:-/usr}"
QMLDIR="${QMLDIR:-$PREFIX/lib/qt6/qml}"

TARGET="$DESTDIR$QMLDIR/QuickMotion"

if [ -z "$DESTDIR" ] && [ "$(id -u)" -ne 0 ]; then
    echo "needs root: sudo $0 $*" >&2
    exit 1
fi

if [ "${1:-}" = "--uninstall" ]; then
    rm -rf "$TARGET"
    echo "removed $TARGET"
    exit 0
fi

install -d "$TARGET"
install -m 0644 "$here"/QuickMotion/*.qml "$here"/QuickMotion/qmldir "$TARGET/"

echo "installed to $TARGET"
echo
echo "use it with:"
echo "    import QuickMotion"
echo "    Behavior on x { Anim { role: Motion.Reveal } }"

#!/usr/bin/env bash
# Installs the QuickMotion QML module.
#
#   sudo ./install.sh                 install system-wide
#   ./install.sh --user               install for this user only, no root
#   sudo ./install.sh --uninstall     remove it
#   DESTDIR=/tmp/pkg ./install.sh     stage into a package root
#
# Goes into Qt's QML import path, so consumers write `import QuickMotion`
# with no path juggling. Quickshell reads that path like any Qt program.

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

DESTDIR="${DESTDIR:-}"
PREFIX="${PREFIX:-/usr}"

# Qt's QML import path differs per distribution — /usr/lib/qt6/qml on Arch,
# /usr/lib64/qt6/qml on Fedora, /usr/lib/x86_64-linux-gnu/qt6/qml on Debian.
# Hardcoding one of them means the install reports success and the import
# fails, with nothing connecting the two. Ask Qt instead.
qt_qmldir() {
    local q
    for q in qmake6 qtpaths6 "$PREFIX/lib/qt6/bin/qmake6" /usr/lib/qt6/bin/qmake6; do
        if command -v "$q" >/dev/null 2>&1; then
            case "$q" in
                *qtpaths6) "$q" --query QT_INSTALL_QML 2>/dev/null && return ;;
                *) "$q" -query QT_INSTALL_QML 2>/dev/null && return ;;
            esac
        fi
    done
    echo "$PREFIX/lib/qt6/qml"
}


mode=install
user_install=0

for arg in "$@"; do
    case "$arg" in
        --uninstall) mode=uninstall ;;
        --user) user_install=1 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

# A user install needs no root and survives a distribution upgrade, which is
# what anyone trying the library out actually wants. Qt does not search this
# path on its own — verified, not assumed — so it has to be pointed at it,
# and the instructions below say so rather than hoping.
if [ "$user_install" = 1 ]; then
    QMLDIR="${QMLDIR:-${XDG_DATA_HOME:-$HOME/.local/share}/qt6/qml}"
else
    QMLDIR="${QMLDIR:-$(qt_qmldir)}"
fi

TARGET="$DESTDIR$QMLDIR/QuickMotion"

if [ -z "$DESTDIR" ] && [ "$user_install" = 0 ] && [ "$(id -u)" -ne 0 ]; then
    echo "needs root for a system install: sudo $0 $*" >&2
    echo "or install for yourself alone:   $0 --user" >&2
    exit 1
fi

if [ "$mode" = uninstall ]; then
    rm -rf "$TARGET"
    echo "removed $TARGET"
    exit 0
fi


install -d "$TARGET"
install -m 0644 "$here"/QuickMotion/*.qml "$here"/QuickMotion/qmldir "$TARGET/"

# ─────────────────────────────── shaders ───────────────────────────────
#
# The GLSL sources are installed alongside the compiled .qsb, so what is
# running can be read where it is running rather than only in the
# repository. A shader binary nobody can inspect is a poor thing to ship.
install -d "$TARGET/shaders"
install -m 0644 "$here"/QuickMotion/shaders/* "$TARGET/shaders/"

# And rebuilt against the local Qt when the tools are here. A .qsb carries
# the shader in the intermediate formats the baking Qt knew about; the
# committed ones come from whichever version the author had, and there is no
# reason to make every consumer inherit that choice when their own qsb is
# one command away. Falling back to the committed binaries keeps
# qt6-shadertools an optional dependency rather than a required one.
qsb=""
for candidate in qsb "$PREFIX/lib/qt6/bin/qsb" /usr/lib/qt6/bin/qsb; do
    if command -v "$candidate" >/dev/null 2>&1; then
        qsb="$candidate"
        break
    fi
done

if [ -n "$qsb" ]; then
    rebuilt=0
    for src in "$here"/QuickMotion/shaders/*.vert "$here"/QuickMotion/shaders/*.frag; do
        [ -e "$src" ] || continue
        # Tested rather than left to set -e. This step is optional: a qsb
        # that is present but fails leaves the committed blobs already in
        # place, and aborting here would fail the whole install — and any
        # package build — over an optional improvement.
        if "$qsb" --qt6 -o "$TARGET/shaders/$(basename "$src").qsb" "$src"; then
            rebuilt=$((rebuilt + 1))
        else
            echo "  warning: could not rebuild $(basename "$src"), keeping the committed blob" >&2
        fi
    done
    echo "rebuilt $rebuilt shaders with $qsb"
else
    echo "qsb not found — using the shaders committed to the repository"
    echo "  install qt6-shadertools to rebuild them against your Qt"
fi

echo
echo "installed to $TARGET"

if [ "$user_install" = 1 ]; then
    cat <<EOT

Qt does not search this path by default, so point it there. For the shell
you are in now:

    export QML_IMPORT_PATH="$QMLDIR:\$QML_IMPORT_PATH"

For every session, on a systemd machine:

    mkdir -p ~/.config/environment.d
    echo 'QML_IMPORT_PATH=$QMLDIR' > ~/.config/environment.d/50-quickmotion.conf

Nothing here writes that for you — an installer editing your session
environment unasked is worse than one extra command.
EOT
fi

echo
echo "use it with:"
echo "    import QuickMotion"
echo "    Behavior on x { Anim { role: Motion.Reveal } }"

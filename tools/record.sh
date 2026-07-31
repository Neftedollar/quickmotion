#!/usr/bin/env bash
# Records the README animations.
#
#   ./tools/record.sh              every scene
#   ./tools/record.sh edge genie   only these
#
# Renders a PNG per frame from tools/scenes/*.qml, then assembles a looping
# GIF. Needs quickshell and ffmpeg; nothing here runs during an install.

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out="$here/docs"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

FRAMES="${FRAMES:-72}"
FPS="${FPS:-25}"
WIDTH="${WIDTH:-640}"

mkdir -p "$out"

scenes=("$@")
if [ ${#scenes[@]} -eq 0 ]; then
    scenes=()
    for f in "$here"/tools/scenes/*.qml; do
        scenes+=("$(basename "$f" .qml)")
    done
fi

for scene in "${scenes[@]}"; do
    src="$here/tools/scenes/$scene.qml"
    [ -f "$src" ] || { echo "no such scene: $scene" >&2; exit 1; }

    echo "recording $scene…"
    rm -f "$tmp"/*.png

    QML_IMPORT_PATH="$here" QML2_IMPORT_PATH="$here" \
        QM_SCENE="$src" QM_FRAMES="$FRAMES" QM_OUT="$tmp/f" \
        qs -p "$here/tools/record.qml" >/dev/null 2>&1 || true

    count=$(find "$tmp" -name 'f_*.png' | wc -l)
    if [ "$count" -lt "$FRAMES" ]; then
        echo "  only $count of $FRAMES frames — is quickshell able to open a window?" >&2
        exit 1
    fi

    # Two passes. A GIF has 256 colours total, and letting ffmpeg pick them
    # from the whole sequence rather than per frame is the difference between
    # a clean gradient and visible banding — which on a glow is the entire
    # subject of the image.
    ffmpeg -y -loglevel error -framerate "$FPS" -i "$tmp/f_%04d.png" \
        -vf "scale=$WIDTH:-1:flags=lanczos,palettegen=stats_mode=diff" \
        "$tmp/palette.png"

    ffmpeg -y -loglevel error -framerate "$FPS" -i "$tmp/f_%04d.png" -i "$tmp/palette.png" \
        -lavfi "scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
        -loop 0 "$out/$scene.gif"

    printf '  %s → %s\n' "$scene.gif" "$(du -h "$out/$scene.gif" | cut -f1)"
done

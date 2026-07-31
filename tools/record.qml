import QtQuick
import Quickshell

// Frame recorder for the README animations.
//
//     QM_SCENE=tools/scenes/edge.qml QM_FRAMES=72 QM_OUT=/tmp/f qs -p tools/record.qml
//
// Deliberately not a screen recording. Scenes here are a function of `t`
// rather than of the clock: the recorder sets `t` from 0 to just under 1 and
// grabs a frame at each step, so the last frame leads back into the first
// and the loop is seamless. Recording a running animation instead samples
// wherever the compositor happened to be, and the seam shows.
//
// It also means a frame costs whatever it costs. Nothing is dropped, and the
// result is identical on a fast machine and a slow one.
ShellRoot {
    id: root

    property string scenePath: Quickshell.env("QM_SCENE") || ""
    property int frames: parseInt(Quickshell.env("QM_FRAMES") || "72")
    property string outPrefix: Quickshell.env("QM_OUT") || "/tmp/qmframe"
    property real supersample: parseFloat(Quickshell.env("QM_SS") || "2")

    property int frame: 0

    FloatingWindow {
        id: win

        implicitWidth: loader.item ? loader.item.implicitWidth : 640
        implicitHeight: loader.item ? loader.item.implicitHeight : 360
        color: "#0d1117"

        // Grabbed instead of the window's own content item: quickshell's
        // is a proxy with no QML engine behind it, and grabToImage on it
        // fails every frame. A plain Item works, and carrying the
        // background inside it means the frames are not transparent.
        Item {
            id: canvas

            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: win.color
            }

            Loader {
                id: loader

                anchors.fill: parent
                source: root.scenePath
            }
        }

        // A beat before the first grab: shaders compile on first use, and a
        // frame captured before that is a frame of nothing.
        Timer {
            id: warmup

            running: true
            interval: 900
            onTriggered: step.start()
        }

        Timer {
            id: step

            interval: 40
            repeat: true

            onTriggered: {
                if (!loader.item) {
                    return;
                }

                // Just under 1 at the last frame, never 1 itself — t = 1 is
                // t = 0 again for anything cyclic, and grabbing both puts a
                // duplicate frame in every loop.
                loader.item.t = root.frame / root.frames;

                const n = String(root.frame).padStart(4, "0");
                canvas.grabToImage(function (result) {
                    result.saveToFile(`${root.outPrefix}_${n}.png`);
                }, Qt.size(canvas.width * root.supersample, canvas.height * root.supersample));

                if (++root.frame >= root.frames) {
                    step.stop();
                    // One more spin of the loop so the final grab lands
                    // before the process goes away.
                    done.start();
                }
            }
        }

        Timer {
            id: done

            interval: 600
            onTriggered: Qt.quit()
        }
    }
}

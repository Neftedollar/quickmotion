import QtQuick
import QuickMotion

// MotionShape's ten shapes, and a colour walking the hue circle under them.
Item {
    id: scene

    property real t: 0

    implicitWidth: 640
    implicitHeight: 180

    ColourCycle {
        id: hue

        running: false
        position: scene.t
    }

    Row {
        anchors.centerIn: parent
        spacing: 16

        Repeater {
            model: 10

            Item {
                required property int index

                width: 46
                height: 46

                MotionShape {
                    anchors.fill: parent
                    kind: index
                    // Each shape a little further round the circle, so the
                    // row reads as one sweep rather than ten blinks.
                    color: Qt.hsva((scene.t + index / 20) % 1, 0.58, 0.96, 1)
                    // Turning slowly: a still polygon hides that these are
                    // drawn rather than imaged.
                    rotation: scene.t * 360 * (index % 2 === 0 ? 1 : -1)
                }
            }
        }
    }
}

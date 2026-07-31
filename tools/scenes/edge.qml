import QtQuick
import QuickMotion

// EdgeLight on three proportions at once — the point being that the light
// keeps one speed on all of them.
Item {
    id: scene

    property real t: 0

    implicitWidth: 640
    implicitHeight: 220

    Row {
        anchors.centerIn: parent
        spacing: 26

        Repeater {
            model: [
                { w: 150, h: 110, r: 16, n: 1, c: "#8ab4f8" },
                { w: 230, h: 52, r: 26, n: 2, c: "#28c941" },
                { w: 110, h: 130, r: 20, n: 1, c: "#ff6159" }
            ]

            Item {
                required property var modelData

                width: modelData.w
                height: 150

                Rectangle {
                    id: plate

                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.modelData.h
                    radius: parent.modelData.r
                    color: "#161d26"
                }

                EdgeLight {
                    anchors.fill: plate
                    rounding: plate.radius
                    lightColour: parent.modelData.c
                    trackColour: "#1e2732"
                    thickness: 2.5
                    glow: 11
                    tail: 0.26
                    count: parent.modelData.n
                    running: false
                    progress: scene.t
                }
            }
        }
    }
}

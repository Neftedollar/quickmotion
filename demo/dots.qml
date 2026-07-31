import QtQuick
import Quickshell
import QuickMotion

// Drives a row of dots up and down on its own, so the exit animation can
// actually be seen. A Repeater-based row is impossible to film: its
// delegates are gone before the first frame of any removal.
ShellRoot {
    FloatingWindow {
        id: win

        implicitWidth: 420
        implicitHeight: 140
        color: "#101418"
        visible: true

        property int count: 0
        property int dir: 1

        Timer {
            interval: 260
            running: true
            repeat: true
            onTriggered: {
                if (win.count >= 8)
                    win.dir = -1;
                else if (win.count <= 0)
                    win.dir = 1;
                win.count += win.dir;
            }
        }

        AnimatedRow {
            anchors.centerIn: parent
            height: 20
            model: win.count
            itemWidth: 9
            gap: 7
            travel: 6

            delegate: Rectangle {
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                width: 9
                height: 9
                radius: width / 2
                color: "#a3c9e9"
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            text: "QuickMotion · AnimatedRow"
            color: "#8a9297"
            font.pixelSize: 12
        }
    }
}

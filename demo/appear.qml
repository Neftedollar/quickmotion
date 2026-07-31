import QtQuick
import Quickshell
import QuickMotion

// Один и тот же компонент, разные наборы эффектов.
ShellRoot {
    FloatingWindow {
        id: win

        implicitWidth: 560; implicitHeight: 260
        color: "#101418"; visible: true

        property bool toggled: false
        Timer { interval: 1700; running: true; repeat: true; onTriggered: win.toggled = !win.toggled }

        Row {
            anchors.centerIn: parent
            spacing: 26

            // только затухание
            Item {
                width: 90; height: 90
                Rectangle { id: a; anchors.fill: parent; radius: 16; color: "#a3c9e9" }
                Appear { target: a; shown: win.toggled }
                Text { anchors.top: parent.bottom; anchors.topMargin: 8
                       anchors.horizontalCenter: parent.horizontalCenter
                       text: "fade"; color: "#6d7876"; font.pixelSize: 11 }
            }

            // затухание и масштаб
            Item {
                width: 90; height: 90
                Rectangle { id: b; anchors.fill: parent; radius: 16; color: "#a3c9e9" }
                Appear { target: b; shown: win.toggled; scale: 0.5 }
                Text { anchors.top: parent.bottom; anchors.topMargin: 8
                       anchors.horizontalCenter: parent.horizontalCenter
                       text: "+ scale"; color: "#6d7876"; font.pixelSize: 11 }
            }

            // и подлёт снизу
            Item {
                width: 90; height: 90
                Rectangle { id: c; anchors.fill: parent; radius: 16; color: "#a3c9e9" }
                Appear { target: c; shown: win.toggled; scale: 0.8; slide: 40; from: Appear.Bottom }
                Text { anchors.top: parent.bottom; anchors.topMargin: 8
                       anchors.horizontalCenter: parent.horizontalCenter
                       text: "+ slide"; color: "#6d7876"; font.pixelSize: 11 }
            }

            // и поворот
            Item {
                width: 90; height: 90
                Rectangle { id: d; anchors.fill: parent; radius: 16; color: "#a3c9e9" }
                Appear { target: d; shown: win.toggled; scale: 0.6; slide: 30; from: Appear.Right; spin: -25 }
                Text { anchors.top: parent.bottom; anchors.topMargin: 8
                       anchors.horizontalCenter: parent.horizontalCenter
                       text: "+ spin"; color: "#6d7876"; font.pixelSize: 11 }
            }
        }
    }
}

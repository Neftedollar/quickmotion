import QtQuick
import Quickshell
import QuickMotion

// Проверяет, что все компоненты грузятся и работают вместе.
ShellRoot {
    FloatingWindow {
        id: win
        implicitWidth: 560; implicitHeight: 320
        color: "#101418"; visible: true

        property bool flag: false
        Timer { interval: 1600; running: true; repeat: true; onTriggered: win.flag = !win.flag }

        Column {
            anchors.centerIn: parent
            spacing: 18

            // AnimatedRow с разбросом
            ListModel { id: dots }
            Timer {
                interval: 300; running: true; repeat: true
                property int dir: 1
                onTriggered: {
                    if (dots.count >= 6) dir = -1; else if (dots.count <= 0) dir = 1;
                    dir > 0 ? dots.append({}) : dots.remove(dots.count-1);
                }
            }
            AnimatedRow {
                height: 24; model: dots; itemWidth: 12; gap: 8; jitter: 0.3
                delegate: Rectangle {
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    width: 12; height: 12; radius: 6; color: "#a3c9e9"
                }
            }

            // Pressable
            Pressable {
                id: press
                width: 120; height: 36
                down: win.flag
                Rectangle {
                    anchors.fill: parent; radius: height/2; color: "#22485f"
                    Text { anchors.centerIn: parent; text: "Pressable"; color: "#a3c9e9" }
                }
            }

            // Reveal
            Reveal {
                open: win.flag
                Rectangle { width: 200; height: 50; radius: 12; color: "#1c2024"
                    Text { anchors.centerIn: parent; text: "Reveal"; color: "#c0c7cd" } }
            }

            // SlideIn + Shake
            Item {
                width: 200; height: 40
                SlideIn {
                    id: sl
                    anchors.fill: parent
                    edge: SlideIn.Left
                    shown: win.flag
                    Rectangle { anchors.fill: parent; radius: 12; color: "#262a2e"
                        Text { anchors.centerIn: parent; text: "SlideIn"; color: "#c0c7cd" } }
                }
            }

            Rectangle {
                id: shakeMe
                width: 200; height: 36; radius: 12; color: "#3a2226"
                Text { anchors.centerIn: parent; text: "Shake"; color: "#ffb4ab" }
                Shake { id: sh; target: shakeMe; property: "x" }
                Timer { interval: 1600; running: true; repeat: true; onTriggered: sh.restart() }
            }
        }
    }
}

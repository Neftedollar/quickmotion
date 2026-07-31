import QtQuick
import Quickshell
import QuickMotion

// Три языка движения на одном и том же перемещении.
//
// Каждая строка спрашивает свой профиль через curveIn/durationIn, не
// трогая активный: подмена глобального профиля внутри привязки — цикл.
ShellRoot {
    FloatingWindow {
        id: win
        implicitWidth: 520; implicitHeight: 220
        color: "#101418"; visible: true

        property bool out: false
        Timer { interval: 1600; running: true; repeat: true; onTriggered: win.out = !win.out }

        Column {
            anchors.centerIn: parent
            spacing: 26

            Repeater {
                model: [
                    { name: "Material",  p: Motion.Material },
                    { name: "Cupertino", p: Motion.Cupertino },
                    { name: "Adwaita",   p: Motion.Adwaita }
                ]

                delegate: Row {
                    required property var modelData
                    spacing: 16

                    Text {
                        width: 92
                        text: modelData.name
                        color: "#8a9297"
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: 360; height: 28
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: "#a3c9e9"
                            x: win.out ? 332 : 0

                            Behavior on x {
                                NumberAnimation {
                                    duration: Motion.durationIn(modelData.p, Motion.Reveal)
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.curveIn(modelData.p, Motion.Reveal)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import QuickMotion

// Four docks, four directions. The point of showing all of them at once is
// that the funnel axis follows the target rather than the endpoint moving
// under a fixed vertical squeeze.
ShellRoot {
    FloatingWindow {
        implicitWidth: 900
        implicitHeight: 620
        color: "#101418"

        Item {
            id: stage

            anchors.fill: parent

            // The four destinations, at the middle of each edge.
            Repeater {
                model: [
                    {
                        edge: Genie.BottomEdge,
                        x: 0.5,
                        y: 1.0
                    },
                    {
                        edge: Genie.TopEdge,
                        x: 0.5,
                        y: 0.0
                    },
                    {
                        edge: Genie.LeftEdge,
                        x: 0.0,
                        y: 0.5
                    },
                    {
                        edge: Genie.RightEdge,
                        x: 1.0,
                        y: 0.5
                    }
                ]

                Rectangle {
                    required property var modelData

                    width: 46
                    height: 46
                    radius: 12
                    color: stage.edge === modelData.edge ? "#8ab4f8" : "#2a3038"
                    border.width: 1
                    border.color: "#3d444d"

                    x: modelData.x * stage.width - width / 2
                    y: modelData.y * stage.height - height / 2

                    Behavior on color {
                        ColourAnim {}
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (stage.collapsed) {
                                stage.collapsed = false;
                                return;
                            }
                            stage.edge = parent.modelData.edge;
                            stage.collapsed = true;
                        }
                    }
                }
            }

            property int edge: Genie.BottomEdge
            property bool collapsed: false

            // ─────────────────────── the thing that pours ───────────────────────

            Item {
                id: windowContent

                width: 380
                height: 250
                anchors.centerIn: parent
                visible: false

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#2b3a55"
                        }
                        GradientStop {
                            position: 1
                            color: "#1b2233"
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 14
                        color: "#36405a"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            spacing: 7

                            Repeater {
                                model: ["#ff6159", "#ffbd2e", "#28c941"]

                                Rectangle {
                                    required property string modelData

                                    width: 11
                                    height: 11
                                    radius: 6
                                    color: modelData
                                }
                            }
                        }
                    }

                    // Something with structure, so the warp is legible. A
                    // flat fill hides the whole effect.
                    Grid {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 16
                        columns: 8
                        spacing: 10

                        Repeater {
                            model: 32

                            Rectangle {
                                required property int index

                                width: 30
                                height: 18
                                radius: 5
                                color: index % 3 === 0 ? "#8ab4f8" : "#4a5a7a"
                            }
                        }
                    }
                }
            }

            Genie {
                anchors.fill: windowContent
                sourceItem: windowContent
                edge: stage.edge
                minimized: stage.collapsed
                neckWidth: neck.value

                targetX: {
                    if (stage.edge === Genie.LeftEdge)
                        return -windowContent.x;
                    if (stage.edge === Genie.RightEdge)
                        return stage.width - windowContent.x;
                    return width / 2;
                }
                targetY: {
                    if (stage.edge === Genie.TopEdge)
                        return -windowContent.y;
                    if (stage.edge === Genie.BottomEdge)
                        return stage.height - windowContent.y;
                    return height / 2;
                }
            }

            // ──────────────────────────── controls ────────────────────────────

            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 78
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: "#9aa4b2"
                    font.pixelSize: 13
                    text: stage.collapsed ? "click any dock to restore" : "click a dock to pour into it"
                }

                Row {
                    id: neck

                    property real value: 0.35

                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Repeater {
                        model: [0.18, 0.35, 0.60, 0.90]

                        Rectangle {
                            required property real modelData

                            width: 62
                            height: 28
                            radius: 14
                            color: Math.abs(neck.value - modelData) < 0.001 ? "#8ab4f8" : "#252b33"

                            Behavior on color {
                                ColourAnim {}
                            }

                            Text {
                                anchors.centerIn: parent
                                text: `neck ${parent.modelData}`
                                font.pixelSize: 11
                                color: Math.abs(neck.value - parent.modelData) < 0.001 ? "#0f1419" : "#9aa4b2"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: neck.value = parent.modelData
                            }
                        }
                    }
                }
            }
        }
    }
}

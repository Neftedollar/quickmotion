import QtQuick
import QuickMotion

// The same surface poured into each of the four edges.
Item {
    id: scene

    property real t: 0

    implicitWidth: 640
    implicitHeight: 220

    // Out and back, so the loop returns to a whole window.
    readonly property real p: scene.t < 0.5 ? scene.t * 2 : (1 - scene.t) * 2

    Row {
        anchors.centerIn: parent
        spacing: 14

        Repeater {
            model: [Genie.BottomEdge, Genie.TopEdge, Genie.LeftEdge, Genie.RightEdge]

            Item {
                required property int modelData

                width: 150
                height: 170

                Item {
                    id: src

                    anchors.fill: parent
                    anchors.margins: 12
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "#2b3a55"

                        Grid {
                            anchors.centerIn: parent
                            columns: 4
                            spacing: 7

                            Repeater {
                                model: 16

                                Rectangle {
                                    required property int index

                                    width: 22
                                    height: 13
                                    radius: 3
                                    color: index % 3 === 0 ? "#8ab4f8" : "#4a5a7a"
                                }
                            }
                        }
                    }
                }

                Genie {
                    anchors.fill: src
                    sourceItem: src
                    edge: parent.modelData
                    progress: scene.p
                }
            }
        }
    }
}

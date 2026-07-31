import QtQuick
import Quickshell
import QuickMotion

// Contact sheet: every direction at every stage, held still.
//
// An animation cannot be checked by reading the shader — the whole point of
// the axis fix is what the geometry looks like part-way through, and that
// is only visible in a frame. Rows are directions, columns are progress.
ShellRoot {
    FloatingWindow {
        implicitWidth: 4 * 210 + 30
        implicitHeight: 4 * 150 + 30
        color: "#0d1117"

        Grid {
            id: sheet

            anchors.centerIn: parent
            columns: 4
            spacing: 6

            readonly property var stages: [0.0, 0.3, 0.55, 0.8]
            readonly property var edges: [Genie.BottomEdge, Genie.TopEdge, Genie.LeftEdge, Genie.RightEdge]

            Repeater {
                model: 16

                Item {
                    id: tile

                    required property int index

                    readonly property int edge: sheet.edges[Math.floor(index / 4)]
                    readonly property real stage: sheet.stages[index % 4]

                    width: 204
                    height: 144

                    Rectangle {
                        anchors.fill: parent
                        color: "#141a21"
                        radius: 6
                    }

                    Item {
                        id: cell

                        anchors.fill: parent
                        anchors.margins: 14

                        Item {
                            id: src

                            anchors.fill: parent
                            visible: false

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: "#2b3a55"

                                Grid {
                                    anchors.centerIn: parent
                                    columns: 6
                                    spacing: 6

                                    Repeater {
                                        model: 24

                                        Rectangle {
                                            required property int index

                                            width: 20
                                            height: 12
                                            radius: 3
                                            color: index % 3 === 0 ? "#8ab4f8" : "#4a5a7a"
                                        }
                                    }
                                }
                            }
                        }

                        Genie {
                            anchors.fill: parent
                            sourceItem: src
                            edge: tile.edge
                            // Assigned rather than bound to `minimized`:
                            // this sheet wants the mid-animation shapes,
                            // which no run of the animation holds still.
                            progress: tile.stage
                        }
                    }
                }
            }
        }

        // Not Component.onCompleted: at that point the item has no window
        // yet and grabToImage has nothing to render into.
        Timer {
            running: true
            interval: 1200
            onTriggered: sheet.grabToImage(function (result) {
                result.saveToFile("/tmp/claude-1000/-home-roman/0f607323-5383-49f9-a686-bffc43ab0883/scratchpad/genie-sheet.png");
                Qt.callLater(Qt.quit);
            }, Qt.size(sheet.width * 2, sheet.height * 2))
        }
    }
}

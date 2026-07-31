import QtQuick
import Quickshell
import QuickMotion

// Contact sheet for EdgeLight, held still at four points of the lap.
//
// Three proportions on purpose. The whole claim of the arc-length
// parameterisation is that the light keeps one speed whatever the shape, and
// that claim is only testable on a square, a wide bar and a tall panel side
// by side: with an angle sweep the wide row visibly outruns the others.
ShellRoot {
    FloatingWindow {
        implicitWidth: 940
        implicitHeight: 560
        color: "#0d1117"

        Column {
            id: sheet

            anchors.centerIn: parent
            spacing: 18

            readonly property var stages: [0.0, 0.25, 0.5, 0.75]

            Repeater {
                model: [
                    {
                        w: 180,
                        h: 120,
                        r: 16
                    },
                    {
                        w: 200,
                        h: 44,
                        r: 22
                    },
                    {
                        w: 90,
                        h: 150,
                        r: 12
                    }
                ]

                Row {
                    id: band

                    required property var modelData

                    spacing: 18

                    Repeater {
                        model: sheet.stages

                        Item {
                            required property real modelData

                            width: 210
                            height: 160

                            Rectangle {
                                id: plate

                                anchors.centerIn: parent
                                width: band.modelData.w
                                height: band.modelData.h
                                radius: band.modelData.r
                                color: "#1a222c"
                            }

                            EdgeLight {
                                anchors.fill: plate
                                rounding: plate.radius
                                lightColour: "#8ab4f8"
                                trackColour: "#26303c"
                                thickness: 2.5
                                glow: 9
                                tail: 0.3
                                // Assigned, not bound to `running`: the
                                // sheet wants positions no run holds still.
                                progress: parent.modelData
                                running: false
                            }
                        }
                    }
                }
            }

            // Two lights, and a rainbow one, to show count and ColourCycle.
            Row {
                spacing: 18

                ColourCycle {
                    id: hue

                    running: false
                    position: 0.55
                }

                Repeater {
                    model: [
                        {
                            n: 2,
                            c: "#8ab4f8",
                            p: 0.0
                        },
                        {
                            n: 3,
                            c: "#28c941",
                            p: 0.1
                        },
                        {
                            n: 1,
                            c: "#ff6159",
                            p: 0.4
                        },
                        {
                            n: 1,
                            c: hue.colour,
                            p: 0.4
                        }
                    ]

                    Item {
                        required property var modelData

                        width: 210
                        height: 130

                        Rectangle {
                            id: card

                            anchors.centerIn: parent
                            width: 180
                            height: 100
                            radius: 26
                            color: "#1a222c"
                        }

                        EdgeLight {
                            anchors.fill: card
                            rounding: card.radius
                            lightColour: parent.modelData.c
                            thickness: 3
                            glow: 12
                            tail: 0.35
                            count: parent.modelData.n
                            progress: parent.modelData.p
                            running: false
                        }
                    }
                }
            }
        }

        Timer {
            running: true
            interval: 1200
            onTriggered: sheet.grabToImage(function (result) {
                result.saveToFile("/tmp/claude-1000/-home-roman/0f607323-5383-49f9-a686-bffc43ab0883/scratchpad/edge-sheet.png");
                Qt.callLater(Qt.quit);
            }, Qt.size(sheet.width * 1.6, sheet.height * 1.6))
        }
    }
}

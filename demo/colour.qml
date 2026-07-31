import QtQuick
import Quickshell
import QuickMotion

// ColourCycle and EdgeLight, together and apart.
ShellRoot {
    FloatingWindow {
        implicitWidth: 880
        implicitHeight: 620
        color: "#0d1117"

        // One rainbow, shared. Several things reading the same cycle stay in
        // step, which is usually what is wanted; give them their own for
        // colours that should differ.
        ColourCycle {
            id: rainbow
        }

        ColourCycle {
            id: brand

            colours: ["#8ab4f8", "#28c941", "#ffbd2e", "#ff6159"]
            period: Motion.ms(9000)
        }

        Column {
            anchors.centerIn: parent
            spacing: 26

            // ── a card wearing a light of the cycling colour ──
            Item {
                width: 480
                height: 150
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: card

                    anchors.fill: parent
                    radius: 20
                    color: "#161d26"

                    Text {
                        anchors.centerIn: parent
                        text: "EdgeLight + ColourCycle"
                        color: rainbow.colour
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }
                }

                EdgeLight {
                    anchors.fill: card
                    rounding: card.radius
                    lightColour: rainbow.colour
                    trackColour: "#212b36"
                    thickness: 2.5
                    glow: 12
                    tail: 0.3
                }
            }

            // ── proportions, to show the light keeps one speed ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22

                Repeater {
                    model: [
                        {
                            w: 150,
                            h: 110,
                            r: 16,
                            n: 1
                        },
                        {
                            w: 260,
                            h: 46,
                            r: 23,
                            n: 2
                        },
                        {
                            w: 100,
                            h: 110,
                            r: 40,
                            n: 3
                        }
                    ]

                    Item {
                        required property var modelData

                        width: modelData.w
                        height: 120

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
                            lightColour: brand.colour
                            thickness: 2.5
                            glow: 10
                            count: parent.modelData.n
                            tail: 0.28
                        }
                    }
                }
            }

            // ── three colours on one outline ──
            //
            // `count` repeats a single colour, so several colours means
            // several lights stacked and pulled apart by phase.
            Item {
                width: 480
                height: 96
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: strip

                    anchors.fill: parent
                    radius: 24
                    color: "#161d26"

                    Text {
                        anchors.centerIn: parent
                        text: "three lights, three phases"
                        color: "#7e8894"
                        font.pixelSize: 13
                    }
                }

                Repeater {
                    model: [
                        {
                            c: "#8ab4f8",
                            p: 0.0
                        },
                        {
                            c: "#ff6159",
                            p: 1 / 3
                        },
                        {
                            c: "#28c941",
                            p: 2 / 3
                        }
                    ]

                    EdgeLight {
                        required property var modelData

                        anchors.fill: strip
                        rounding: strip.radius
                        lightColour: modelData.c
                        thickness: 2.5
                        glow: 11
                        tail: 0.2
                        phase: modelData.p
                        period: Motion.ms(4200)
                    }
                }
            }

            // ── the cycles themselves, unadorned ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22

                Repeater {
                    model: [
                        {
                            label: "hue circle",
                            c: rainbow
                        },
                        {
                            label: "palette",
                            c: brand
                        }
                    ]

                    Column {
                        required property var modelData

                        spacing: 8

                        Rectangle {
                            width: 220
                            height: 54
                            radius: 12
                            color: parent.modelData.c.colour
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.modelData.label
                            color: "#7e8894"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 520
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#5c6672"
                font.pixelSize: 12
                text: "The light is parameterised by arc length, so it travels at one speed on all three shapes. Sweeping an angle instead would race along the short sides."
            }
        }
    }
}

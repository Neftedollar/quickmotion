import QtQuick

// A control that acknowledges a touch and settles when released.
//
// Wrap the visual and bind `down`:
//
//     Pressable {
//         down: area.pressed
//         Rectangle { anchors.fill: parent; ... }
//     }
//
// Press and release are deliberately not symmetric. Acknowledging a touch
// has to feel instant or the control reads as laggy; letting go should
// settle or it reads as hasty. Equal timing manages to feel like both.
Item {
    id: root

    property bool down: false

    // How far the control gives under a press.
    property real depth: 0.04

    readonly property real pressedScale: 1 - depth

    scale: down ? pressedScale : 1

    Behavior on scale {
        Anim {
            role: root.down ? Motion.Press : Motion.Release
        }
    }
}

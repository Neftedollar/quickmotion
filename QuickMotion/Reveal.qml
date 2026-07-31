import QtQuick

// A container that grows and shrinks with its content.
//
// Wrap the content and bind `open`. The size follows the content when open
// and collapses to nothing when closed, with the content fading so it reads
// as hidden rather than squashed.
//
//     Reveal {
//         open: expanded
//         Column { ... }
//     }
//
// clip is on because content spilling past a collapsing edge is the
// commonest way this looks broken.
Item {
    id: root

    default property alias content: holder.data

    property bool open: false

    // Which dimension collapses. Rows collapse horizontally.
    property bool vertical: true

    clip: true

    // Measured through childrenRect, not implicitHeight.
    //
    // A plain Item does not derive its size from its children: its
    // implicit size stays zero however much is inside it. Reading that
    // instead means the container collapses to nothing and never opens —
    // it lays out correctly, throws no error, and simply draws nothing.
    readonly property real _contentWidth: holder.childrenRect.width
    readonly property real _contentHeight: holder.childrenRect.height

    implicitWidth: !vertical && !open ? 0 : _contentWidth
    implicitHeight: vertical && !open ? 0 : _contentHeight

    Behavior on implicitHeight {
        enabled: root.vertical

        Anim {
            role: Motion.Resize
        }
    }

    Behavior on implicitWidth {
        enabled: !root.vertical

        Anim {
            role: Motion.Resize
        }
    }

    Item {
        id: holder

        // Sized from its own children rather than from the parent, which
        // is mid-animation and would drag the content along with it.
        width: childrenRect.width
        height: childrenRect.height

        opacity: root.open ? 1 : 0

        Behavior on opacity {
            Anim {
                role: Motion.Fade
            }
        }
    }
}

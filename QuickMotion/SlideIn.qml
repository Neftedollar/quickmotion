import QtQuick

// A panel arriving from an edge.
//
// For layer-shell surfaces and anything else anchored to a side: bars,
// drawers, on-screen displays. Bind `shown` and set `edge`.
//
//     SlideIn {
//         edge: SlideIn.TopEdge
//         shown: visible
//         Rectangle { ... }
//     }
//
// Entry and exit use different curves on purpose. Something arriving is
// worth watching and decelerates into place; something leaving should get
// out of the way, so it accelerates out. Using one curve for both makes
// dismissal feel reluctant.
Item {
    id: root

    // Spelled with the Edge suffix because Item already defines Top,
    // Bottom, Left and Right as transform origins, and a base type's enum
    // shadows one declared here — the plain names never reach this
    // declaration at all.
    enum Edge {
        TopEdge,
        BottomEdge,
        LeftEdge,
        RightEdge
    }

    default property alias content: holder.data

    property int edge: SlideIn.TopEdge
    property bool shown: true

    // How far outside its own bounds the panel starts. Defaults to its own
    // size, so it begins fully off the edge.
    property real distance: (edge === SlideIn.TopEdge || edge === SlideIn.BottomEdge) ? height : width

    readonly property real _dx: {
        if (shown)
            return 0;
        if (edge === SlideIn.LeftEdge)
            return -distance;
        if (edge === SlideIn.RightEdge)
            return distance;
        return 0;
    }

    readonly property real _dy: {
        if (shown)
            return 0;
        if (edge === SlideIn.TopEdge)
            return -distance;
        if (edge === SlideIn.BottomEdge)
            return distance;
        return 0;
    }

    Item {
        id: holder

        anchors.fill: parent

        x: root._dx
        y: root._dy
        opacity: root.shown ? 1 : 0

        Behavior on x {
            Anim {
                role: root.shown ? Motion.Reveal : Motion.Dismiss
            }
        }

        Behavior on y {
            Anim {
                role: root.shown ? Motion.Reveal : Motion.Dismiss
            }
        }

        Behavior on opacity {
            Anim {
                role: Motion.Fade
            }
        }
    }
}

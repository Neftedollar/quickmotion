import QtQuick

// Swapping content that is a step forward or back in the same flow.
//
//     SharedAxis {
//         index: step
//         axis: SharedAxis.X
//         Component { UserList {} }
//         Component { PasswordEntry {} }
//     }
//
// Direction carries the meaning. Going forward, the old content leaves
// towards the start of the axis and the new arrives from the end; going
// back, both reverse. That is the whole difference from FadeThrough, and it
// is why `index` going down does not look like `index` going up: someone
// who has pressed Back should see the screen retrace its steps.
//
// The Z axis is the odd one and the most useful: rather than sliding, the
// outgoing content scales away and the incoming grows in, which reads as
// moving inward through a hierarchy rather than sideways along it.
//
// Both halves fade as they travel, so the two are never both solid at once.
Item {
    id: root

    enum Axis {
        X,
        Y,
        Z
    }

    property int index: 0
    default property list<Component> pages

    property int axis: SharedAxis.X

    // How far the sliding axes travel. The spec's is 30dp — far enough to
    // read as a direction, near enough that it never looks like the content
    // came from off screen.
    property real distance: 30

    // Z scales instead of sliding. Outgoing shrinks towards this, incoming
    // grows from it.
    property real depth: 0.8

    signal swapped

    property int _shown: 0
    property bool _forward: true

    onIndexChanged: {
        if (index === _shown)
            return;
        _forward = index > _shown;
        swap.restart();
    }

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property real _travel: _forward ? -distance : distance

    property real _baseX: 0
    property real _baseY: 0

    Component.onCompleted: {
        _baseX = loader.x;
        _baseY = loader.y;
    }

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: root._shown >= 0 && root._shown < root.pages.length ? root.pages[root._shown] : null
        transformOrigin: Item.Center
    }

    SequentialAnimation {
        id: swap

        ParallelAnimation {
            Anim {
                target: loader
                property: "opacity"
                to: 0
                role: Motion.Dismiss
            }
            Anim {
                target: loader
                property: "x"
                to: root._baseX + (root.axis === SharedAxis.X ? root._travel : 0)
                role: Motion.Dismiss
                duration: root.axis === SharedAxis.X ? Motion.durationFor(Motion.Dismiss) : 0
            }
            Anim {
                target: loader
                property: "y"
                to: root._baseY + (root.axis === SharedAxis.Y ? root._travel : 0)
                role: Motion.Dismiss
                duration: root.axis === SharedAxis.Y ? Motion.durationFor(Motion.Dismiss) : 0
            }
            Anim {
                target: loader
                property: "scale"
                // Going forward is going deeper, so the old layer grows past
                // the viewer; going back it recedes. Scaling one way for
                // both directions loses the sense of depth entirely.
                to: root.axis === SharedAxis.Z ? (root._forward ? 1 / root.depth : root.depth) : 1
                role: Motion.Dismiss
                duration: root.axis === SharedAxis.Z ? Motion.durationFor(Motion.Dismiss) : 0
            }
        }

        // Placed on the far side before it is shown, so the first frame of
        // the arrival is already off to one side rather than in place.
        ScriptAction {
            script: {
                root._shown = root.index;
                if (root.axis === SharedAxis.X)
                    loader.x = root._baseX - root._travel;
                if (root.axis === SharedAxis.Y)
                    loader.y = root._baseY - root._travel;
                if (root.axis === SharedAxis.Z)
                    loader.scale = root._forward ? root.depth : 1 / root.depth;
            }
        }

        ParallelAnimation {
            Anim {
                target: loader
                property: "opacity"
                to: 1
                role: Motion.Fade
            }
            Anim {
                target: loader
                property: "x"
                to: root._baseX
                role: Motion.Reveal
                duration: root.axis === SharedAxis.X ? Motion.durationFor(Motion.Reveal) : 0
            }
            Anim {
                target: loader
                property: "y"
                to: root._baseY
                role: Motion.Reveal
                duration: root.axis === SharedAxis.Y ? Motion.durationFor(Motion.Reveal) : 0
            }
            Anim {
                target: loader
                property: "scale"
                to: 1
                role: Motion.Reveal
                duration: root.axis === SharedAxis.Z ? Motion.durationFor(Motion.Reveal) : 0
            }
        }

        onFinished: root.swapped()
    }
}

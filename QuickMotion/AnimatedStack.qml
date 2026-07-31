import QtQuick

// Content replacing content.
//
// The outgoing item leaves while the incoming one arrives, overlapping
// briefly rather than handing over cleanly. A gap between them reads as a
// flicker; a hard cut reads as a jump. The overlap is what makes it a
// transition at all.
//
//     AnimatedStack {
//         source: promptSecret ? passwordComp : codeComp
//     }
//
// Direction matters: set `forward` false when going back, and the motion
// reverses so returning does not feel like advancing again.
Item {
    id: root

    property Component source: null
    property bool forward: true

    // How far items travel. Zero gives a plain crossfade, which is the
    // right choice when the two contents are unrelated.
    property int travel: 16

    implicitWidth: current.item ? current.item.implicitWidth : 0
    implicitHeight: current.item ? current.item.implicitHeight : 0

    Behavior on implicitWidth {
        Anim {
            role: Motion.Resize
        }
    }

    Behavior on implicitHeight {
        Anim {
            role: Motion.Resize
        }
    }

    onSourceChanged: {
        if (!current.sourceComponent) {
            current.sourceComponent = source;
            return;
        }
        // The outgoing item moves to the other loader so the incoming one
        // can take over `current` without waiting for it to finish.
        outgoing.sourceComponent = current.sourceComponent;
        leave.restart();
        current.sourceComponent = source;
        enter.restart();
    }

        // Sized rather than anchored, and this is not a style choice.
        // QQuickAnchors owns x and y under `fill` or `centerIn`, so a
        // binding or animation on either is overwritten every layout pass —
        // silently, from the first frame. This component's whole purpose is
        // to move something, and anchored it moved exactly zero pixels.
    //
    // Centring is therefore done by hand. `y` is a plain binding because
    // nothing animates it; `x` gets only its resting value, so the
    // animations below are free to drive it.
    Loader {
        id: outgoing

        y: (root.height - height) / 2
        opacity: 0
    }

    Loader {
        id: current

        y: (root.height - height) / 2
    }

    ParallelAnimation {
        id: enter

        Anim {
            target: current
            property: "opacity"
            from: 0
            to: 1
            role: Motion.Fade
        }
        Anim {
            target: current
            property: "x"
            from: root.forward ? root.travel : -root.travel
            to: 0
            role: Motion.Reveal
        }
    }

    ParallelAnimation {
        id: leave

        Anim {
            target: outgoing
            property: "opacity"
            from: 1
            to: 0
            role: Motion.Fade
        }
        Anim {
            target: outgoing
            property: "x"
            from: 0
            to: root.forward ? -root.travel : root.travel
            role: Motion.Dismiss
        }

        onFinished: outgoing.sourceComponent = null
    }
}

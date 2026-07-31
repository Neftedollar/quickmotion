import QtQuick

// Swapping content that has nothing to do with what it replaces.
//
//     FadeThrough {
//         index: page
//         Component { Item { /* … */ } }
//         Component { Item { /* … */ } }
//     }
//
// Not a crossfade, and the difference is the point. A crossfade overlaps
// the two, so for half its length the screen shows a blend of both — two
// sets of text on top of each other, legible as neither. This clears the
// old one out first and only then brings the new one in, so nothing is ever
// composited over anything else.
//
// The incoming content also grows very slightly into place, from 92%. The
// scale is small enough not to read as movement; it reads as arriving from
// somewhere rather than materialising, and without it the sequence looks
// like a light being switched off and on.
//
// Use SharedAxis instead when the two are related — a step forward in the
// same flow — where direction carries meaning that a fade throws away.
Item {
    id: root

    // Which child to show.
    property int index: 0

    // Content, one Component per position.
    default property list<Component> pages

    // Where the incoming content starts. 1 disables the growth and leaves a
    // pure out-then-in fade.
    property real fromScale: 0.92

    readonly property int outDuration: Motion.durationFor(Motion.Dismiss)
    readonly property int inDuration: Motion.durationFor(Motion.Reveal)

    signal swapped

    property int _shown: 0

    onIndexChanged: {
        if (index === _shown)
            return;
        swap.restart();
    }

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: root._shown >= 0 && root._shown < root.pages.length ? root.pages[root._shown] : null

        opacity: 1
        scale: 1
        transformOrigin: Item.Center
    }

    SequentialAnimation {
        id: swap

        // Out first, and completely. Anything still on screen when the new
        // content starts appearing is the crossfade this exists to avoid.
        ParallelAnimation {
            Anim {
                target: loader
                property: "opacity"
                to: 0
                role: Motion.Dismiss
            }
            Anim {
                target: loader
                property: "scale"
                to: root.fromScale
                role: Motion.Dismiss
                duration: root.fromScale !== 1 ? Motion.durationFor(Motion.Dismiss) : 0
            }
        }

        ScriptAction {
            script: {
                root._shown = root.index;
                loader.scale = root.fromScale;
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
                property: "scale"
                to: 1
                role: Motion.Reveal
                duration: root.fromScale !== 1 ? Motion.durationFor(Motion.Reveal) : 0
            }
        }

        onFinished: root.swapped()
    }
}

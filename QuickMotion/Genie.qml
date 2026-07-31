import QtQuick

// The macOS minimise: a surface pours into a point.
//
// Worth saying plainly, because it is the usual misconception — this is not
// a sequence of animations. There is no shrink, then a bend, then a slide.
// One number goes from 0 to 1 and a vertex shader remaps the geometry
// nonlinearly; everything that looks like choreography falls out of the
// remapping. Nothing here can be built out of NumberAnimations, which is
// why this is the one component in the library that ships a shader.
//
//     Genie {
//         anchors.fill: parent
//         sourceItem: window
//         edge: Genie.BottomEdge
//         targetX: dockIcon.x + dockIcon.width / 2
//         targetY: dock.y
//         minimized: collapsed
//     }
//
// `edge` is not decoration. It says which side of the surface reaches the
// target first, and the funnel is built along that axis: the front sweeps
// in from that edge while the two perpendicular sides squeeze together.
// Point at a dock on the left and the surface narrows vertically, not
// horizontally. Getting this wrong is what makes a genie read as a slide.
//
// The source is hidden and drawn by this item instead, so place it over the
// region the source occupies. At progress 0 the mesh is the identity and
// the result is pixel-for-pixel the original.
ShaderEffect {
    id: root

    // Which side leads — the one nearest the target. Order matches the
    // `direction` uniform and must not be reshuffled.
    //
    // Spelled with the Edge suffix because Item already defines Top,
    // Bottom, Left and Right as transform origins, and a base type's enum
    // shadows one declared here — the plain names never reach this
    // declaration at all.
    enum Edge {
        BottomEdge,
        TopEdge,
        LeftEdge,
        RightEdge
    }

    required property Item sourceItem

    property int edge: Genie.BottomEdge

    // Where it pours to, in this item's coordinates. The default is the
    // middle of the leading edge, which collapses in place — useful for
    // seeing the shape of the effect before wiring up a real destination.
    property real targetX: {
        if (edge === Genie.LeftEdge)
            return 0;
        if (edge === Genie.RightEdge)
            return width;
        return width / 2;
    }
    property real targetY: {
        if (edge === Genie.TopEdge)
            return 0;
        if (edge === Genie.BottomEdge)
            return height;
        return height / 2;
    }

    // How much of the surface is inside the funnel at once. Small values
    // give a tight spout that whips through; large ones a long stretch
    // closer to a fold. Below about 0.15 the mesh is too coarse to bend
    // smoothly and the neck goes faceted.
    property real neckWidth: 0.35

    property bool minimized: false

    // Genie is deliberately not run off a Motion role. The spatial roles
    // overshoot, and progress above 1 is clamped in the shader — the effect
    // would finish early and then sit still for the rest of the animation.
    property int duration: Motion.ms(520)
    property var easing: Motion.curve.standard

    signal finished

    // ─────────────────────────── uniforms ───────────────────────────

    property real progress: minimized ? 1 : 0

    // The shader wants a float; the enum is an int.
    readonly property real direction: root.edge

    property variant source: ShaderEffectSource {
        sourceItem: root.sourceItem
        hideSource: true
        live: true
    }

    Behavior on progress {
        SequentialAnimation {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.Bezier
                easing.bezierCurve: root.easing
            }
            ScriptAction {
                script: root.finished()
            }
        }
    }

    // ──────────────────────────── geometry ────────────────────────────

    // Dense along the axis the funnel travels, sparse across it: the neck
    // curves in one direction only, and vertices spent on the other are
    // vertices spent on nothing. A uniform grid fine enough for the neck
    // costs several times this.
    mesh: GridMesh {
        readonly property bool _horizontal: root.edge === Genie.LeftEdge || root.edge === Genie.RightEdge

        resolution: _horizontal ? Qt.size(64, 12) : Qt.size(12, 64)
    }

    // Resolved explicitly against this file. A bare relative path is
    // resolved against the root document instead, so it works only when the
    // application happens to sit one directory above the shaders — which
    // for an installed module is never.
    vertexShader: Qt.resolvedUrl("shaders/genie.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/genie.frag.qsb")
}

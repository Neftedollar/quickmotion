import QtQuick

// Light travelling along an edge.
//
//     EdgeLight {
//         anchors.fill: card
//         rounding: card.radius
//         lightColour: "#8ab4f8"
//     }
//
// Traces the bounds it is given, so fill it to whatever it should outline
// and match the corner radius. `trackColour` lights the whole outline
// faintly underneath, which keeps the border from vanishing between passes.
//
// Two things make this more than a gradient.
//
// The travel is parameterised by arc length. Sweeping an angle around the
// centre is the obvious approach and it is wrong on anything but a square:
// equal angles cover unequal distance, so the light races along the short
// sides and crawls along the long ones — unmissable on a bar. Here the
// outline is measured as four straight runs and four quarter arcs laid end
// to end, so the speed is the same the whole way round whatever the
// proportions.
//
// And the glow is drawn outside the traced bounds. A shader can only paint
// within its own geometry, so an effect sized exactly to the shape has its
// halo cut off square at the edges — a hard box around the light, far more
// noticeable than the light. The surface is inflated by `bleed` and the
// outline inset by the same amount, which puts the bounds back where the
// caller expects them and still leaves the halo somewhere to go.
//
// Pair it with ColourCycle for a light that changes colour as it goes:
//
//     ColourCycle { id: hue }
//     EdgeLight { lightColour: hue.colour }
Item {
    id: root

    property color lightColour: "#8ab4f8"

    // The always-on part of the outline. Transparent by default, so what
    // you get is a light in the dark rather than a lit border.
    property color trackColour: "transparent"

    property real thickness: 2

    // Match this to the radius of whatever is being traced. A light that
    // corners more sharply than the thing under it is the giveaway.
    property real rounding: 0

    // Edge softness in pixels. Below 1 the outline aliases; well above it
    // the line stops being a line.
    property real softness: 1

    // Length of the comet as a fraction of the gap between lights, so it
    // stays proportionate as `count` changes.
    property real tail: 0.22

    // Evenly spaced around the lap.
    property real count: 1

    // Falloff of the halo outside the outline, in pixels. 0 draws a bare
    // line with no bloom.
    property real glow: 7

    // How far the drawn surface reaches past the traced bounds. The default
    // is four falloff lengths, by which point the halo is under 2% and the
    // cut is invisible. Lower it only if something above is being overdrawn.
    property real bleed: glow * 4 + thickness

    // One lap.
    property int period: Motion.ms(2800)

    property bool running: true

    property real progress: 0

    // Offset into the lap, 0 to 1. `count` repeats one colour; several
    // colours means several of these stacked, and then they need pulling
    // apart or they ride on top of each other. Same period, different
    // phase, and they hold their spacing for as long as they run:
    //
    //     EdgeLight { lightColour: "#8ab4f8" }
    //     EdgeLight { lightColour: "#ff6159"; phase: 1 / 3 }
    //     EdgeLight { lightColour: "#28c941"; phase: 2 / 3 }
    //
    // Stacking is the answer rather than a list of colours per light: each
    // one then gets its own tail, glow and thickness too, and where they
    // overlap the colours mix rather than one winning.
    property real phase: 0

    // Linear: a lap has no beginning to ease out of and no end to ease
    // into, and any curve puts a hesitation at the seam.
    //
    // Infinite only while there is motion to have. This is decoration,
    // unlike Spin, so Motion.scale of 0 should stop it — and stopping has
    // to mean not looping, never a zero-length duration. Looping one of
    // those forever spins the event loop rather than the light.
    NumberAnimation on progress {
        running: root.running
        loops: Motion.scale > 0 ? Animation.Infinite : 1
        from: 0
        to: 1
        duration: root.period
        easing.type: Easing.Linear
    }

    // Deliberately larger than its parent. Qt Quick does not clip children
    // unless asked, so this paints past the item's bounds and the halo
    // survives; `inset` tells the shader the outline is still at the
    // caller's geometry.
    ShaderEffect {
        anchors.fill: parent
        anchors.margins: -root.bleed

        readonly property real itemW: width
        readonly property real itemH: height
        readonly property real inset: root.bleed

        readonly property color lightColour: root.lightColour
        readonly property color trackColour: root.trackColour
        readonly property real thickness: root.thickness
        readonly property real rounding: root.rounding
        readonly property real softness: root.softness
        readonly property real tail: root.tail
        readonly property real count: root.count
        readonly property real glow: root.glow
        // Wrapped in the shader, so a phase past the end of the lap is fine.
        readonly property real progress: root.progress + root.phase

        // Resolved against this file rather than the root document — see
        // Genie for what a bare relative path does instead.
        vertexShader: Qt.resolvedUrl("shaders/edgelight.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/edgelight.frag.qsb")
    }
}

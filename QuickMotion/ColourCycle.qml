import QtQuick

// A colour that keeps moving: a rainbow, or a lap around a palette.
//
//     ColourCycle { id: rainbow }
//     Rectangle { color: rainbow.colour }
//
//     ColourCycle {
//         id: brand
//         colours: ["#8ab4f8", "#28c941", "#ffbd2e"]
//     }
//
// It produces a colour and nothing else — no rectangle, no gradient, no
// opinion about what is being painted. Bind `colour` wherever a colour
// goes: a fill, a border, an EdgeLight, the text of one label.
//
// With `colours` empty it walks the whole hue circle. Given a list it walks
// that instead, blending each into the next and wrapping from the last back
// to the first, so a three-colour list is a loop and not a three-step
// sequence that snaps at the end.
QtObject {
    id: root

    // Empty means the full hue circle.
    property var colours: []

    // Only used for the hue circle. A fully saturated rainbow is
    // unusable behind text, hence the restraint by default.
    property real saturation: 0.60
    property real brightness: 0.96
    property real alpha: 1.0

    // One full lap. Slow on purpose: a rainbow that turns over in a second
    // is a novelty, one that takes half a minute is ambience.
    property int period: Motion.ms(24000)

    property bool running: true

    // Where in the lap it currently is, 0 to 1. Exposed so several cycles
    // can be offset from one another — two lights chasing round a card look
    // wrong sharing a phase and right a third of a lap apart.
    property real position: 0

    readonly property color colour: _sample(position)

    // The hue circle is walked in HSV, which is not perceptually even: the
    // greens are broad and the blues narrow, so a constant rate lingers in
    // some parts of the circle and hurries through others. Correcting it
    // means a perceptual space QML does not have, and for ambient colour the
    // unevenness reads as variation rather than as error. Pass `colours`
    // when the exact hues matter.
    function _sample(p) {
        const n = colours ? colours.length : 0;
        const f = p - Math.floor(p);

        if (n === 0)
            return Qt.hsva(f, saturation, brightness, alpha);
        if (n === 1)
            return colours[0];

        const scaled = f * n;
        const i = Math.floor(scaled);
        return _blend(colours[i % n], colours[(i + 1) % n], scaled - i);
    }

    function _blend(a, b, t) {
        const ca = Qt.color(a);
        const cb = Qt.color(b);
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, ca.a + (cb.a - ca.a) * t);
    }

    // Linear, because a lap has no beginning to ease out of and no end to
    // ease into. Any curve here puts a hesitation at the seam.
    //
    // Infinite only while there is motion to have: Motion.scale of 0 must
    // stop this rather than shorten it, since a zero-length animation
    // looping forever spins the event loop instead of the colour.
    NumberAnimation on position {
        running: root.running
        loops: Motion.scale > 0 ? Animation.Infinite : 1
        from: 0
        to: 1
        duration: root.period
        easing.type: Easing.Linear
    }
}

pragma Singleton

import QtQuick

// Material 3 Expressive motion, as published in the Material Design
// specification. Curves and durations only — no opinion about what moves.
//
// The central rule this encodes: a curve and its duration are one thing,
// not two knobs. Spatial curves overshoot and need room to settle;
// effect curves do not and would look sluggish given that room. Mixing a
// spatial curve with an effects duration is what makes motion feel wrong
// in a way nobody can name, and it is the usual result of picking each
// value independently.
//
// Roles are named by what is happening, not by which curve is used. A
// caller writing `Motion.reveal` keeps working when the specification
// changes its numbers; one writing `OutBack, 420ms` does not.
QtObject {
    id: root

    // Global multiplier. 0 disables animation outright, which is what
    // accessibility settings and remote sessions want.
    property real scale: 1.0

    function ms(base: int): int {
        return Math.max(0, Math.round(base * root.scale));
    }

    // ─────────────────────────── curves ───────────────────────────

    // QML wants a bezier as [x1, y1, x2, y2, 1, 1].

    readonly property QtObject curve: QtObject {
        // Expressive spatial — position, size, shape. These overshoot:
        // the second control point rises above 1 and settles back.
        readonly property var fastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property var spatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property var slowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]

        // Expressive effects — opacity, colour. No overshoot: a colour
        // cannot overshoot, and an opacity that does looks like a flicker.
        readonly property var fastEffects: [0.31, 0.94, 0.34, 1.00, 1, 1]
        readonly property var effects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property var slowEffects: [0.34, 0.88, 0.34, 1.00, 1, 1]

        // Classic M3, still the right choice for anything that should not
        // draw attention to itself.
        readonly property var standard: [0.20, 0.00, 0.00, 1.00, 1, 1]
        readonly property var standardAccel: [0.30, 0.00, 1.00, 1.00, 1, 1]
        readonly property var standardDecel: [0.00, 0.00, 0.00, 1.00, 1, 1]

        readonly property var emphasized: [0.20, 0.00, 0.00, 1.00, 1, 1]
        readonly property var emphasizedAccel: [0.30, 0.00, 0.80, 0.15, 1, 1]
        readonly property var emphasizedDecel: [0.05, 0.70, 0.10, 1.00, 1, 1]
    }

    // ────────────────────────── durations ──────────────────────────

    readonly property QtObject dur: QtObject {
        readonly property int fastSpatial: root.ms(350)
        readonly property int spatial: root.ms(500)
        readonly property int slowSpatial: root.ms(650)

        readonly property int fastEffects: root.ms(150)
        readonly property int effects: root.ms(200)
        readonly property int slowEffects: root.ms(300)

        readonly property int standard: root.ms(300)
        readonly property int standardAccel: root.ms(200)
        readonly property int standardDecel: root.ms(250)

        readonly property int emphasized: root.ms(500)
        readonly property int emphasizedAccel: root.ms(200)
        readonly property int emphasizedDecel: root.ms(400)
    }

    // ─────────────────────────── roles ───────────────────────────

    // What most callers should reach for. Each pairs a curve with the
    // duration it was designed against.
    //
    // Press is deliberately quicker than release: acknowledging a touch
    // must feel instant, while letting go should settle. Symmetric timing
    // there reads as lag on the way in and as haste on the way out.
    enum Role {
        Press,      // a control acknowledging a touch
        Release,    // the same control letting go
        Reveal,     // something arriving on screen
        Dismiss,    // something leaving
        Resize,     // a container following its content
        Emphasis,   // drawing attention deliberately
        Fade,       // opacity only
        Tint        // colour only
    }

    function curveFor(role: int): var {
        switch (role) {
        case Motion.Press:
            return curve.emphasizedAccel;
        case Motion.Release:
            return curve.emphasizedDecel;
        case Motion.Reveal:
            return curve.spatial;
        case Motion.Dismiss:
            return curve.standardAccel;
        case Motion.Resize:
            return curve.fastSpatial;
        case Motion.Emphasis:
            return curve.slowSpatial;
        case Motion.Fade:
            return curve.effects;
        case Motion.Tint:
            return curve.fastEffects;
        }
        return curve.standard;
    }

    function durationFor(role: int): int {
        switch (role) {
        case Motion.Press:
            return dur.fastEffects;
        case Motion.Release:
            return dur.emphasizedDecel;
        case Motion.Reveal:
            return dur.spatial;
        case Motion.Dismiss:
            return dur.standardAccel;
        case Motion.Resize:
            return dur.fastSpatial;
        case Motion.Emphasis:
            return dur.slowSpatial;
        case Motion.Fade:
            return dur.effects;
        case Motion.Tint:
            return dur.fastEffects;
        }
        return dur.standard;
    }
}

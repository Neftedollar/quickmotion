pragma Singleton

import QtQuick

// Motion languages for QML: Material 3 Expressive, Apple's spring-driven
// style, and GNOME's deliberately quiet one. Curves and durations only —
// no opinion about what moves.
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

    // ────────────────────────── profiles ──────────────────────────

    // Which motion language the roles resolve into.
    //
    // These are three genuinely different systems, not three palettes of
    // the same one. Material announces itself: things overshoot, hold, and
    // settle. Cupertino is spring-driven, with a single soft bounce and
    // tight damping. Adwaita is deliberately quiet — critically damped,
    // no overshoot anywhere, and roughly half the duration.
    //
    // Approximations, and honestly so. Cupertino and Adwaita are both
    // spring-based at source, and a cubic bezier cannot express more than
    // one oscillation. For a single soft bounce it is indistinguishable;
    // for anything springier it is not, and Qt's SpringAnimation is the
    // right tool instead.
    enum Profile {
        Material,   // Material 3 Expressive
        Cupertino,  // Apple, spring-flavoured
        Adwaita     // GNOME / libadwaita
    }

    property int profile: Motion.Material

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

    // Query a profile other than the active one.
    //
    // Without this the only way to compare profiles is to assign to
    // `profile`, read, and assign back — which inside a binding is a loop,
    // and outside one is a race with anything else reading it.
    function curveIn(which: int, role: int): var {
        if (which === Motion.Cupertino)
            return _cupertinoCurve(role);
        if (which === Motion.Adwaita)
            return _adwaitaCurve(role);
        return _materialCurve(role);
    }

    function durationIn(which: int, role: int): int {
        if (which === Motion.Cupertino)
            return _cupertinoDuration(role);
        if (which === Motion.Adwaita)
            return _adwaitaDuration(role);
        return _materialDuration(role);
    }

    function curveFor(role: int): var {
        return curveIn(profile, role);
    }

    function durationFor(role: int): int {
        return durationIn(profile, role);
    }

    function _materialCurve(role: int): var {
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

    function _materialDuration(role: int): int {
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

    // ─────────────────────────── Cupertino ───────────────────────────

    // Apple's motion is spring-driven; SwiftUI's default is a response of
    // about 0.55s with a damping fraction near 0.83, which lands as a
    // single soft overshoot rather than a bounce. The curves below carry
    // that overshoot; the durations are the springs' settling times.
    readonly property QtObject cupertino: QtObject {
        readonly property var spring: [0.34, 1.16, 0.36, 1.00, 1, 1]
        readonly property var softSpring: [0.32, 1.08, 0.38, 1.00, 1, 1]
        readonly property var quick: [0.25, 0.10, 0.25, 1.00, 1, 1]
        readonly property var out: [0.16, 1.00, 0.30, 1.00, 1, 1]
        readonly property var into: [0.40, 0.00, 1.00, 1.00, 1, 1]
    }

    function _cupertinoCurve(role: int): var {
        switch (role) {
        case Motion.Press:
            return cupertino.into;
        case Motion.Release:
            return cupertino.softSpring;
        case Motion.Reveal:
            return cupertino.spring;
        case Motion.Dismiss:
            return cupertino.into;
        case Motion.Resize:
            return cupertino.softSpring;
        case Motion.Emphasis:
            return cupertino.spring;
        case Motion.Fade:
            return cupertino.quick;
        case Motion.Tint:
            return cupertino.quick;
        }
        return cupertino.out;
    }

    function _cupertinoDuration(role: int): int {
        switch (role) {
        case Motion.Press:
            return ms(120);
        case Motion.Release:
            return ms(400);
        case Motion.Reveal:
            return ms(550);
        case Motion.Dismiss:
            return ms(250);
        case Motion.Resize:
            return ms(400);
        case Motion.Emphasis:
            return ms(700);
        case Motion.Fade:
            return ms(250);
        case Motion.Tint:
            return ms(200);
        }
        return ms(350);
    }

    // ──────────────────────────── Adwaita ────────────────────────────

    // GNOME's springs are critically damped: they reach the target and
    // stop, with no overshoot at any point. Durations are roughly half
    // Material's. The result is motion you notice only if you look for it,
    // which is the intent — libadwaita treats animation as feedback rather
    // than as expression.
    readonly property QtObject adwaita: QtObject {
        readonly property var ease: [0.33, 1.00, 0.68, 1.00, 1, 1]
        readonly property var easeIn: [0.32, 0.00, 0.67, 0.00, 1, 1]
        readonly property var easeInOut: [0.65, 0.00, 0.35, 1.00, 1, 1]
    }

    function _adwaitaCurve(role: int): var {
        switch (role) {
        case Motion.Press:
            return adwaita.easeIn;
        case Motion.Dismiss:
            return adwaita.easeIn;
        case Motion.Emphasis:
            return adwaita.easeInOut;
        }
        return adwaita.ease;
    }

    function _adwaitaDuration(role: int): int {
        switch (role) {
        case Motion.Press:
            return ms(100);
        case Motion.Release:
            return ms(200);
        case Motion.Reveal:
            return ms(250);
        case Motion.Dismiss:
            return ms(200);
        case Motion.Resize:
            return ms(250);
        case Motion.Emphasis:
            return ms(400);
        case Motion.Fade:
            return ms(200);
        case Motion.Tint:
            return ms(150);
        }
        return ms(250);
    }
}

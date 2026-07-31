import QtQuick

// Continuous rotation for a busy indicator.
//
//     Spin {
//         target: spinner
//         running: busy
//     }
//
// Linear on purpose. Easing a loop puts an acceleration and a deceleration
// at the seam, so the spinner appears to hesitate once per revolution — the
// one place where an easing curve is unambiguously wrong.
RotationAnimation {
    id: root

    // Inherited from PropertyAnimation rather than declared — redeclaring
    // it here would clash with the base type's own.
    required target

    // One revolution.
    property int period: 900

    // Motion.scale is deliberately not applied, and 0 in particular must
    // not be. A spinner is not decoration: it is the only thing telling
    // anyone the work is still running, and a reduced-motion setting means
    // "no transitions", not "no progress indication".
    //
    // The stronger reason is that scale 0 gives a zero-duration animation
    // looping forever, which does not stop the spinner — it spins the event
    // loop instead, at whatever rate the CPU allows.
    duration: root.period

    loops: Animation.Infinite
    running: false

    from: 0
    to: 360

    // Numerical interpolates the raw number. The other modes exist to pick
    // a path between two angles, which a full turn does not need — stated
    // explicitly so a later edit to `to` cannot quietly change what the
    // mode means.
    direction: RotationAnimation.Numerical

    property: "rotation"

    // Wound back so a spinner shown again does not resume at whatever angle
    // it stopped at.
    onRunningChanged: if (!running && target)
        target.rotation = 0
}

import QtQuick

// A steady pulse: a text caret, a recording dot, anything that has to say
// "still here" without saying anything else.
//
//     Blink {
//         target: caret
//         running: caret.visible
//     }
//
// A loop is not a transition, and the two are timed by different things. A
// transition's duration is how long its curve needs to settle, so changing
// it without changing the curve breaks the pairing every other component
// here is built to protect. A loop's duration is a rhythm — chosen by how
// often it should read, not by the curve — and decoupling them is safe
// only because effect curves do not overshoot. A spatial curve stretched
// over a rhythm would sit visibly overshot at both ends of every cycle.
SequentialAnimation {
    id: root

    required property Item target

    property string property: "opacity"

    property real from: 1
    // Fully off, the caret convention. A softer pulse that never quite
    // disappears is a matter of raising this.
    property real to: 0

    // One full cycle, out and back. Much under 400ms reads as a flicker
    // and much over a second stops reading as alive.
    property int period: Motion.ms(700)

    // Infinite only while there is motion to have. A pulse is decoration,
    // unlike Spin, so Motion.scale of 0 should switch it off — and it has to
    // switch off by not looping, never by reaching the duration. A
    // zero-length animation looping forever does not still the caret: it
    // spins the event loop at whatever rate the CPU allows.
    //
    // A single pass at zero length settles on `from` and ends, which leaves
    // the caret visible and the animation stopped.
    loops: Motion.scale > 0 ? Animation.Infinite : 1

    // Returned to `from` when stopped, so a caret that stops blinking is
    // left visible rather than frozen at whatever opacity it had reached.
    onRunningChanged: if (!running && target)
        target[property] = from

    NumberAnimation {
        target: root.target
        property: root.property
        to: root.to
        duration: root.period / 2
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.curveFor(Motion.Fade)
    }

    NumberAnimation {
        target: root.target
        property: root.property
        to: root.from
        duration: root.period / 2
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.curveFor(Motion.Fade)
    }
}

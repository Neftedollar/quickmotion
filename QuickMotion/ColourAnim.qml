import QtQuick

// ColorAnimation on the effects curves.
//
// Colour is an effect, never spatial: it cannot overshoot, and a curve
// that tries produces a visible flicker as the value passes the target
// and comes back.
ColorAnimation {
    id: root

    property int role: Motion.Tint

    duration: Motion.durationFor(role)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curveFor(role)
}

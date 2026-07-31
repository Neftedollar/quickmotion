import QtQuick

// A NumberAnimation that cannot have its curve and duration disagree.
//
// Both come from one role, so there is no way to pair a spatial curve
// with an effects duration — the mistake that makes motion feel wrong in
// a way nobody can point at.
NumberAnimation {
    id: root

    property int role: Motion.Reveal

    duration: Motion.durationFor(role)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curveFor(role)
}

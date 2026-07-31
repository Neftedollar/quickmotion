import QtQuick

// Refusal feedback: a short lateral shake.
//
// Attach to whatever should recoil and call start(). The target property
// defaults to the anchor offset rather than x, because anything centred
// with anchors ignores x entirely — animating it there does nothing at
// all, silently, which is the usual way this ends up not working.
//
//     Shake { id: shake; target: card }
//     ...
//     onRejected: shake.start()
SequentialAnimation {
    id: root

    required property Item target

    // Anchored items must be moved by their offset. An item positioned by
    // x or inside a layout should set this to "x" instead.
    property string property: "anchors.horizontalCenterOffset"

    property int amplitude: 9
    property int cycles: 2

    loops: cycles

    // Deliberately quick and unsprung. A recoil is an interruption, not a
    // flourish: an easing curve with any weight to it turns a refusal into
    // something that looks pleased with itself.
    NumberAnimation {
        target: root.target
        property: root.property
        to: -root.amplitude
        duration: Motion.ms(55)
    }
    NumberAnimation {
        target: root.target
        property: root.property
        to: root.amplitude
        duration: Motion.ms(55)
    }
    NumberAnimation {
        target: root.target
        property: root.property
        to: 0
        duration: Motion.ms(55)
    }
}

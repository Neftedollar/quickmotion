import QtQuick

// Delay helper for cascading entries.
//
// A list whose items all arrive at once reads as a single block appearing;
// the same items arriving a beat apart read as a list being filled. The
// difference is one multiplication.
//
//     delegate: Item {
//         opacity: 0
//         Component.onCompleted: reveal.start()
//         Anim {
//             id: reveal
//             target: parent; property: "opacity"; to: 1
//             role: Motion.Fade
//             // index comes from the view
//             onStarted: {}
//         }
//         Stagger { id: st; index: model.index }
//     }
QtObject {
    id: root

    required property int index

    // Gap between consecutive items. Below about 20ms the cascade stops
    // being legible and just looks like imprecise timing.
    property int step: 35

    // Beyond this many items the cascade outlasts anyone's patience, so
    // later ones share the last slot rather than extending it further.
    property int maxItems: 12

    readonly property int delay: Motion.ms(Math.min(index, maxItems) * step)
}

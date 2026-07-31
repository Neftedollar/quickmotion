import QtQuick

// A press spreading outward from where it was pressed.
//
//     Rectangle {
//         radius: 16
//         Ripple { anchors.fill: parent; rounding: parent.radius }
//     }
//
// Adds its own MouseArea unless given one, so the common case is two lines
// inside whatever should respond. Hand it an existing `area` when the
// control already has a MouseArea doing other work — two overlapping ones
// mean the lower never sees a press.
//
// Three details separate this from a circle that grows.
//
// It starts where the pointer is, not at the centre. A ripple from the
// centre is a control announcing it was activated; a ripple from the
// pointer is the control acknowledging *you*, and the second thing is the
// entire purpose of the gesture. Keyboard activation has no pointer, so
// `pressCentre()` exists for it.
//
// The fade out is not the reverse of the growth. Release is a wave that
// keeps spreading while it disappears — reversing would suck it back to the
// point of contact, which reads as the press being undone rather than
// accepted. Growth and fade run on separate clocks and the fade never
// rewinds.
//
// And `rounding` is not optional in practice. Qt's clipping is rectangular
// whatever the shape underneath, so a ripple in a rounded control squares
// its corners off on the frame the wave reaches them. Both the wave and the
// mask are drawn here rather than clipped, which costs one shader and no
// texture at all.
Item {
    id: root

    property color colour: "white"

    // Corner radius of the control this sits in. Leave at 0 for square
    // ones; set it to the parent's radius otherwise.
    property real rounding: 0

    // Peak opacity of the wave. The spec's pressed state layer is 0.10, and
    // the ripple rides over whatever hover layer is already there.
    property real intensity: 0.10

    // Set when the control already has a MouseArea; otherwise one is made.
    property MouseArea area: null

    // Switched off through Item's own `enabled`, inherited rather than
    // redeclared — a property of that name would shadow the base one, and
    // Qt says so. The real one is better anyway: it already cascades to the
    // MouseArea below, so a disabled Ripple stops taking input as well as
    // stops drawing.

    readonly property MouseArea _area: area || own

    // Public, because a pointer is not the only way a control is activated.
    // Space or Return on a focused button should ripple too.
    function press(x: real, y: real): void {
        wave.originX = x;
        wave.originY = y;
        grow.restart();
        wave.waveOpacity = root.intensity;
    }

    function pressCentre(): void {
        press(width / 2, height / 2);
    }

    function release(): void {
        fade.restart();
    }

    ShaderEffect {
        id: wave

        anchors.fill: parent

        property real originX: root.width / 2
        property real originY: root.height / 2
        property real waveRadius: 0
        property real waveOpacity: 0

        readonly property real itemW: width
        readonly property real itemH: height
        readonly property real rounding: root.rounding
        readonly property color waveColour: root.colour

        // Nothing to draw until something is pressed, and an invisible
        // ShaderEffect is not rendered at all.
        visible: waveOpacity > 0

        vertexShader: Qt.resolvedUrl("shaders/ripple.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/ripple.frag.qsb")
    }

    MouseArea {
        id: own

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: false
        // Only live when no area was handed in; otherwise it would sit on
        // top of the real one and swallow everything.
        enabled: !root.area
        visible: enabled
    }

    Connections {
        target: root._area
        enabled: root.enabled

        function onPressed(event: var): void {
            root.press(event.x, event.y);
        }

        function onReleased(event: var): void {
            root.release();
        }

        function onCanceled(): void {
            root.release();
        }
    }

    // Far enough to cover the control from wherever it started: the greatest
    // distance from the origin to any corner.
    readonly property real _maxRadius: {
        const dx = Math.max(wave.originX, width - wave.originX);
        const dy = Math.max(wave.originY, height - wave.originY);
        return Math.sqrt(dx * dx + dy * dy);
    }

    // Decelerating: quick away from the finger, slowing as it reaches the
    // edges. Linear looks mechanical; accelerating looks like it is falling
    // over.
    //
    // Taken from the Release role rather than named directly. An earlier
    // version paired Material's emphasizedDecel with the active profile's
    // duration, which under Cupertino or Adwaita is a curve and a duration
    // designed against each other by nobody — the exact fault this library
    // exists to make unwriteable, committed in the library itself.
    Anim {
        id: grow

        target: wave
        property: "waveRadius"
        from: 0
        to: root._maxRadius
        role: Motion.Release
    }

    Anim {
        id: fade

        target: wave
        property: "waveOpacity"
        to: 0
        role: Motion.Fade
    }
}

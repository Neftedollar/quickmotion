import QtQuick

// Entry and exit, composed from whichever effects you want.
//
// Bind `shown` and the target follows it — no play() calls, no state
// machine, nothing to remember to reverse:
//
//     Appear {
//         target: card
//         shown: expanded
//         scale: 0.96
//         slide: 16
//         from: Appear.BottomEdge
//     }
//
// Every effect beyond the fade is off until given a value, so a plain fade
// stays one line and a full entrance stays readable. They compose: fade,
// scale, slide and spin run together on the same curve, which is what
// makes a combination read as one movement rather than three.
//
// Entry and exit use different roles on purpose. Something arriving is
// worth watching; something leaving should get out of the way. One role
// for both makes dismissal feel reluctant — set exitRole to enterRole if
// you disagree.
Item {
    id: root

    // Spelled with the Edge suffix because Item already defines Top,
    // Bottom, Left and Right as transform origins, and a base type's enum
    // shadows one declared here — the plain names never reach this
    // declaration at all.
    enum Edge {
        TopEdge,
        BottomEdge,
        LeftEdge,
        RightEdge
    }

    required property Item target

    property bool shown: true

    // ─────────────────────────── effects ───────────────────────────

    property bool fade: true

    // Scale to start from and shrink back to. 1 disables it.
    property real scale: 1.0

    // Distance travelled. 0 disables it.
    property real slide: 0
    property int from: Appear.BottomEdge

    // Degrees to rotate through. 0 disables it.
    property real spin: 0

    property int enterRole: Motion.Reveal
    property int exitRole: Motion.Dismiss

    // Delay before entering, in real milliseconds. Stagger feeds this and
    // has already applied Motion.scale, so this must not apply it again —
    // scaling twice squares the multiplier and a half-speed cascade comes
    // out at a quarter.
    property int delay: 0

    signal finished

    readonly property int _role: shown ? enterRole : exitRole

    readonly property real _dx: {
        if (slide === 0)
            return 0;
        if (from === Appear.LeftEdge)
            return -slide;
        if (from === Appear.RightEdge)
            return slide;
        return 0;
    }

    readonly property real _dy: {
        if (slide === 0)
            return 0;
        if (from === Appear.TopEdge)
            return -slide;
        if (from === Appear.BottomEdge)
            return slide;
        return 0;
    }

    // Where the target rests when nothing is moving it. Captured once:
    // reading it later would read a value mid-animation and the item would
    // drift a little further every time.
    property real _baseX: 0
    property real _baseY: 0

    // Effects are applied to the target itself rather than to a wrapper.
    // Wrapping would change its parent, and anything positioned by anchors
    // or sitting in a layout would quietly move.
    Component.onCompleted: {
        if (!target)
            return;
        _baseX = target.x;
        _baseY = target.y;
        if (!shown)
            _place(false);
    }

    onShownChanged: anim.restart()

    // Jump straight to a state without animating. Used at startup so an
    // item that begins hidden does not animate itself out on the first
    // frame.
    function _place(visible: bool): void {
        if (!target)
            return;
        if (fade)
            target.opacity = visible ? 1 : 0;
        if (scale !== 1)
            target.scale = visible ? 1 : scale;
        if (_dx !== 0)
            target.x = _baseX + (visible ? 0 : _dx);
        if (_dy !== 0)
            target.y = _baseY + (visible ? 0 : _dy);
        if (spin !== 0)
            target.rotation = visible ? 0 : spin;
    }

    SequentialAnimation {
        id: anim

        PauseAnimation {
            duration: root.shown ? root.delay : 0
        }

        ParallelAnimation {
            // A disabled effect is given no target at all. A zero duration
            // does not leave the property untouched — it writes `to`
            // instantly, so `fade: false` meant "snap opacity" rather than
            // "leave opacity alone", and the default `slide: 0` yanked the
            // target back to wherever it sat at startup on every toggle.
            // Verified by measurement, not assumed.
            Anim {
                target: root.fade ? root.target : null
                property: "opacity"
                to: root.shown ? 1 : 0
                role: Motion.Fade
            }

            Anim {
                target: root.scale !== 1 ? root.target : null
                property: "scale"
                to: root.shown ? 1 : root.scale
                role: root._role
            }

            Anim {
                target: root._dx !== 0 ? root.target : null
                property: "x"
                to: root._baseX + (root.shown ? 0 : root._dx)
                role: root._role
            }

            Anim {
                target: root._dy !== 0 ? root.target : null
                property: "y"
                to: root._baseY + (root.shown ? 0 : root._dy)
                role: root._role
            }

            Anim {
                target: root.spin !== 0 ? root.target : null
                property: "rotation"
                to: root.shown ? 0 : root.spin
                role: root._role
            }
        }

        onFinished: root.finished()
    }
}

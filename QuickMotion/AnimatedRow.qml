import QtQuick

// A horizontal row whose items animate in, out, and out of each other's
// way.
//
// This exists because Repeater cannot do it. Repeater destroys a delegate
// the instant the model shrinks, so there is nothing left to animate —
// which is why a row of password dots built on one snaps when a character
// is deleted, however carefully the entry is animated.
//
// ListView keeps a removed delegate alive for the length of its `remove`
// transition, which is the whole trick. The cost is that the view no
// longer sizes itself from its content while items are leaving, so width
// is tracked deliberately below.
//
// IMPORTANT: the model must be a real model — ListModel, or anything that
// emits insert and remove signals. An integer model looks like it works,
// lays out correctly and updates on every change, but it never emits those
// signals: QML rebuilds the view instead. The transitions below then never
// run, and items appear and vanish instantly with no error anywhere. That
// failure is invisible in code review and only shows up on a screen.
ListView {
    id: root

    // Space between items. Named rather than inherited from `spacing` so
    // the meaning stays obvious at the call site.
    property int gap: 7

    // Distance an arriving item travels, and a departing one retreats.
    property int travel: 0

    // Scale an item grows from and shrinks to. Zero reads as a pop.
    property real fromScale: 0

    // Width of one item. Required whenever the items are uniform, which is
    // the case this component exists for.
    //
    // A ListView only builds delegates that fall inside its viewport, so
    // binding width to contentWidth closes a loop: no width means no
    // delegates, no delegates means no content, no content means no width,
    // and nothing is ever drawn. Computing the width from the count breaks
    // it. Left at 0 the old behaviour returns, which is only correct when
    // something else is driving the width.
    property int itemWidth: 0

    orientation: ListView.Horizontal
    spacing: gap

    // Not a scrollable list: it is a row that happens to animate.
    interactive: false
    reuseItems: false

    // contentWidth lags while a removal is in flight, so the row would
    // visibly jump at the end of the animation if width followed it
    // directly. Animating the change instead makes the container follow
    // its content smoothly, which is what the growth of a password field
    // is made of.
    implicitWidth: itemWidth > 0 ? Math.max(0, count * itemWidth + Math.max(0, count - 1) * gap) : contentWidth
    implicitHeight: contentHeight

    // Delegates must exist before they can animate out, and a departing
    // item sits outside the shrunken viewport by definition.
    cacheBuffer: 4000

    Behavior on implicitWidth {
        Anim {
            role: Motion.Resize
        }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.durationFor(Motion.Fade)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.curveFor(Motion.Fade)
            }
            NumberAnimation {
                property: "scale"
                from: root.fromScale
                to: 1
                duration: Motion.durationFor(Motion.Reveal)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.curveFor(Motion.Reveal)
            }
            NumberAnimation {
                property: "x"
                from: root.travel
                duration: Motion.durationFor(Motion.Reveal)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.curveFor(Motion.Reveal)
            }
        }
    }

    // Leaving is quicker than arriving and uses an accelerating curve:
    // something on its way out should not hold attention on the way.
    remove: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Motion.durationFor(Motion.Dismiss)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.curveFor(Motion.Dismiss)
            }
            NumberAnimation {
                property: "scale"
                to: root.fromScale
                duration: Motion.durationFor(Motion.Dismiss)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.curveFor(Motion.Dismiss)
            }
        }
    }

    // How the survivors close the gap.
    displaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: Motion.durationFor(Motion.Resize)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.curveFor(Motion.Resize)
        }
    }
}

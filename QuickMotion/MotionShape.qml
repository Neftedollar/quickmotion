import QtQuick
import QtQuick.Shapes

// A small filled shape, drawn rather than imaged.
//
// Two formulas cover the whole set: a rounded polygon and a scalloped
// circle. Every kind below is one of those with different arguments, which
// is why adding another is a line rather than a file.
//
//     MotionShape { kind: MotionShape.Sunny; color: "#a3c9e9" }
//
// Set `settlesToCircle` to have it start as `kind` and become a circle shortly
// after. The swap is instantaneous on purpose: masked by whatever size
// change is running at the time it reads as the shape resolving, and it
// costs nothing, whereas morphing between paths of different vertex counts
// costs a great deal and looks worse.
Item {
    id: root

    enum Kind {
        Circle,
        Squircle,
        Triangle,
        Diamond,
        Pentagon,
        Hexagon,
        Sunny,      // few broad lobes
        Cookie,     // many shallow lobes
        Clover,     // four deep lobes
        Burst       // many sharp lobes
    }

    property int kind: MotionShape.Circle
    property color color: "white"

    property bool settlesToCircle: false
    property int settleDelay: 220

    // Chosen from an index rather than at random, so an item rebuilt
    // mid-animation keeps the shape it already had instead of jumping.
    function kindFor(index: int): int {
        const kinds = [MotionShape.Squircle, MotionShape.Triangle, MotionShape.Diamond, MotionShape.Pentagon, MotionShape.Hexagon, MotionShape.Sunny, MotionShape.Cookie, MotionShape.Clover, MotionShape.Burst];
        const n = Math.abs(Math.sin(index * 78.233) * 43758.5453);
        return kinds[Math.floor((n - Math.floor(n)) * kinds.length)];
    }

    property int _current: kind

    onKindChanged: _current = kind

    Component.onCompleted: if (settlesToCircle)
        settle.start()

    Timer {
        id: settle

        interval: root.settleDelay
        repeat: false
        onTriggered: root._current = MotionShape.Circle
    }

    implicitWidth: 16
    implicitHeight: 16

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            fillColor: root.color
            strokeWidth: 0
            strokeColor: "transparent"

            PathSvg {
                path: root._pathFor(root._current, Math.min(root.width, root.height) / 2)
            }
        }
    }

    // ─────────────────────────── geometry ───────────────────────────

    function _pathFor(kind: int, r: real): string {
        const cx = width / 2;
        const cy = height / 2;

        switch (kind) {
        case MotionShape.Circle:
            return _circle(cx, cy, r);
        case MotionShape.Squircle:
            return _polygon(cx, cy, r, 4, 0.55, Math.PI / 4);
        case MotionShape.Triangle:
            return _polygon(cx, cy, r, 3, 0.35, -Math.PI / 2);
        case MotionShape.Diamond:
            return _polygon(cx, cy, r, 4, 0.18, 0);
        case MotionShape.Pentagon:
            return _polygon(cx, cy, r, 5, 0.30, -Math.PI / 2);
        case MotionShape.Hexagon:
            return _polygon(cx, cy, r, 6, 0.28, 0);
        case MotionShape.Sunny:
            return _scallop(cx, cy, r, 8, 0.80);
        case MotionShape.Cookie:
            return _scallop(cx, cy, r, 12, 0.88);
        case MotionShape.Clover:
            return _scallop(cx, cy, r, 4, 0.62);
        case MotionShape.Burst:
            return _scallop(cx, cy, r, 16, 0.78);
        }
        return _circle(cx, cy, r);
    }

    function _circle(cx: real, cy: real, r: real): string {
        // Two half-arcs: a full circle cannot be one arc, since identical
        // start and end points leave the sweep undefined.
        return `M ${cx - r} ${cy} A ${r} ${r} 0 1 1 ${cx + r} ${cy} A ${r} ${r} 0 1 1 ${cx - r} ${cy} Z`;
    }

    // Regular polygon with rounded corners. `round` is the fraction of the
    // edge given over to each corner arc, 0 for sharp and 1 for as round
    // as the edge allows.
    function _polygon(cx: real, cy: real, r: real, sides: int, round: real, rotate: real): string {
        const pts = [];
        for (let i = 0; i < sides; i++) {
            const a = rotate + i * 2 * Math.PI / sides;
            pts.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]);
        }

        let d = "";
        for (let i = 0; i < sides; i++) {
            const prev = pts[(i - 1 + sides) % sides];
            const cur = pts[i];
            const next = pts[(i + 1) % sides];

            // Points where the corner arc leaves and rejoins the edges.
            const inp = _lerp(cur, prev, round / 2);
            const out = _lerp(cur, next, round / 2);

            d += i === 0 ? `M ${inp[0]} ${inp[1]} ` : `L ${inp[0]} ${inp[1]} `;
            // The vertex itself is the control point, which is what makes
            // the corner curve through it rather than to it.
            d += `Q ${cur[0]} ${cur[1]} ${out[0]} ${out[1]} `;
        }
        return d + "Z";
    }

    // Circle with lobes: alternating outer and inner points joined by
    // arcs. `inner` is the inner radius as a fraction of the outer, so
    // values near 1 are gentle ripples and near 0.5 are petals.
    function _scallop(cx: real, cy: real, r: real, lobes: int, inner: real): string {
        const ri = r * inner;
        const step = Math.PI / lobes;
        let d = "";

        for (let i = 0; i < lobes * 2; i++) {
            const a = i * step - Math.PI / 2;
            const rad = i % 2 === 0 ? r : ri;
            const x = cx + rad * Math.cos(a);
            const y = cy + rad * Math.sin(a);

            if (i === 0) {
                d += `M ${x} ${y} `;
            } else {
                // Sweep alternates so lobes bulge outwards and the joins
                // between them cut back in.
                const sweep = i % 2 === 0 ? 1 : 1;
                const ar = (r - ri) / 2 + ri * 0.35;
                d += `A ${ar} ${ar} 0 0 ${sweep} ${x} ${y} `;
            }
        }
        return d + "Z";
    }

    function _lerp(a: var, b: var, t: real): var {
        return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
    }
}

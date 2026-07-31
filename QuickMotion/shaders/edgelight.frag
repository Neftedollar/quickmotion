#version 440

// Light travelling along an edge.
//
// The hard part is not the glow, it is the travel. Sweeping an angle around
// the centre is the obvious way and it is wrong on anything but a square:
// equal angles cover unequal distance, so the light races along the short
// sides and crawls along the long ones. On a bar four times wider than it is
// tall the difference is impossible to miss.
//
// So the outline is parameterised by arc length instead — four straight runs
// and four quarter arcs, measured and laid end to end. The light then moves
// at one speed the whole way round, and the shape of the box stops mattering.

layout(location = 0) in vec2 coord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 lightColour;
    vec4 trackColour;
    float qt_Opacity;
    // 0 to 1, one lap.
    float progress;
    // Width of the drawn outline, in pixels.
    float thickness;
    // Corner radius, matched to whatever it is tracing.
    float rounding;
    // Edge softness in pixels. Under 1 the outline aliases.
    float softness;
    // Length of the comet, as a fraction of the gap between lights.
    float tail;
    // How many lights, evenly spaced around the lap.
    float count;
    // Falloff distance of the halo outside the outline, in pixels. 0 for a
    // bare line.
    float glow;
    float itemW;
    float itemH;
    // How far the drawn surface extends beyond the outline it traces, so
    // the halo has somewhere to go. Without it the glow is cut off square
    // at the item bounds, which is far more visible than the glow itself.
    float inset;
};

const float QUARTER_TURN = 1.57079633;

// Distance travelled to reach this point, measured clockwise from the
// left end of the top edge. Straight runs contribute their length; corners
// contribute their arc.
float arcLength(vec2 q, float a, float b, float r, float arc)
{
    bool pastX = abs(q.x) > a;
    bool pastY = abs(q.y) > b;

    float top = 2.0 * a;
    float right = top + arc + 2.0 * b;
    float bottom = right + arc + 2.0 * a;
    float left = bottom + arc + 2.0 * b;

    if (pastX && pastY) {
        // Within a corner: position is the angle swept through the arc.
        vec2 c = vec2(sign(q.x) * a, sign(q.y) * b);
        float ang = atan(q.y - c.y, q.x - c.x);

        if (q.x > 0.0 && q.y < 0.0)             // top right, -90 to 0
            return top + (ang + QUARTER_TURN) / QUARTER_TURN * arc;
        if (q.x > 0.0)                          // bottom right, 0 to 90
            return right + ang / QUARTER_TURN * arc;
        if (q.y > 0.0)                          // bottom left, 90 to 180
            return bottom + (ang - QUARTER_TURN) / QUARTER_TURN * arc;

        // Top left, 180 to 270. atan returns +180 on the row where the
        // corner starts and -180 just below it; without the wrap the light
        // jumps a whole lap crossing that single row.
        if (ang > 0.0)
            ang -= 4.0 * QUARTER_TURN;
        return left + (ang + 2.0 * QUARTER_TURN) / QUARTER_TURN * arc;
    }

    if (!pastX && q.y < 0.0)
        return q.x + a;
    if (!pastY && q.x > 0.0)
        return top + arc + (q.y + b);
    if (!pastX)
        return right + arc + (a - q.x);
    return bottom + arc + (b - q.y);
}

void main()
{
    vec2 size = vec2(itemW, itemH);
    vec2 q = coord * size - size * 0.5;

    // The outline sits inside the drawn surface by `inset` on every side.
    // Everything below measures against that, not against the item.
    vec2 halfSize = max(size * 0.5 - vec2(inset), vec2(0.5));

    float r = min(rounding, min(halfSize.x, halfSize.y));
    float a = max(halfSize.x - r, 0.0);
    float b = max(halfSize.y - r, 0.0);
    float arc = QUARTER_TURN * r;

    // Signed distance to the rounded outline: negative inside, 0 on it.
    vec2 d = abs(q) - vec2(a, b);
    float sd = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;

    float aa = max(softness, 0.5);
    float halfT = thickness * 0.5;
    float ring = 1.0 - smoothstep(halfT - aa, halfT + aa, abs(sd));

    float perimeter = 4.0 * a + 4.0 * b + 4.0 * arc;
    float t = perimeter > 0.0 ? arcLength(q, a, b, r, arc) / perimeter : 0.0;

    // How far this point sits *behind* the nearest light, in laps —
    // progress minus t, not the other way round. Reversed, the bright end
    // lands at the back and the fade runs ahead of it, which reads as a
    // segment about to be lit rather than as something travelling.
    // Multiplying by count before taking the fraction is what spaces
    // several lights evenly.
    float n = max(count, 1.0);
    // Signed, so there is a front as well as a back: negative ahead of the
    // light, positive behind it, zero at the head itself.
    float behind = fract((progress - t) * n + 0.5) - 0.5;

    float len = clamp(tail, 0.001, 1.0);

    // The head needs a short ramp of its own. Switching brightness on at
    // the head instead leaves a cut straight across the outline, and since
    // the halo is uniform along the edge, that cut is what turns a travelling
    // light into a rectangle with square ends — the tail fades, the front
    // does not, so only the front looks blocky.
    float lead = len * 0.18;

    float front = smoothstep(-lead, 0.0, behind);
    float body = 1.0 - smoothstep(0.0, len, behind);
    float lit = pow(front * body, 1.6);

    // The halo has to die away fast on the inward side. It is symmetric by
    // nature, but this is drawn over the thing it traces, so an inward
    // bloom lands on the card and covers real area — and out there the
    // arc-length parameterisation is meaningless. Points deep inside get
    // classified against whichever edge they are nearest, so `lit` changes
    // in hard rectangular steps and a faint symmetric halo renders those
    // steps as a visible box. Cutting the inward reach removes the box by
    // removing the only place it could show.
    float outward = max(sd - halfT, 0.0);
    float inward = max(-sd - halfT, 0.0);
    float halo = 0.0;
    if (glow > 0.0)
        halo = sd >= 0.0 ? exp(-outward / glow) : exp(-inward / (glow * 0.35));

    float lightA = clamp(ring + halo * 0.7, 0.0, 1.0) * lit * lightColour.a;
    float trackA = ring * trackColour.a;

    // Premultiplied, which is what the scene graph expects.
    vec3 rgb = trackColour.rgb * trackA + lightColour.rgb * lightA;
    float alpha = clamp(trackA + lightA, 0.0, 1.0);

    fragColor = vec4(rgb, alpha) * qt_Opacity;
}

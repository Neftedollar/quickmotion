#version 440

// Genie: a surface poured into a point.
//
// Not a sequence of animations — one parameter drives a nonlinear remapping
// of the geometry, and all the apparent complexity comes out of that. Each
// vertex asks the same question: how far into the funnel am I.
//
// The axis is the whole effect, not a decoration on it. The funnel front
// travels along the direction of the target and the surface converges
// across it: heading for a dock at the bottom, the front sweeps from the
// bottom edge upwards while the sides squeeze together horizontally;
// heading left, the front sweeps in from the left while top and bottom
// squeeze towards each other. Keep a vertical funnel and merely move the
// endpoint sideways and the result slides rather than pours.

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 coord;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // 0 = untouched, 1 = fully drawn in.
    float progress;
    // Where it goes, in this item's coordinates.
    float targetX;
    float targetY;
    // Which edge leads: 0 bottom, 1 top, 2 left, 3 right.
    float direction;
    // Fraction of the surface inside the funnel at any moment. A small
    // neck gives a tight spout and a violent pour; a large one a lazy
    // stretch that reads closer to a fold.
    float neckWidth;
};

void main()
{
    coord = qt_MultiTexCoord0;

    bool horizontal = direction > 1.5;
    // Bottom and right lead with their high-coordinate edge.
    bool leadsAtMax = (direction < 0.5) || (direction > 2.5);

    // Distance from the leading edge, along the axis of travel: 0 at the
    // edge that reaches the target first, 1 at the one that follows last.
    float axis = horizontal ? qt_MultiTexCoord0.x : qt_MultiTexCoord0.y;
    float s = leadsAtMax ? 1.0 - axis : axis;

    // The funnel front, sweeping past the whole surface exactly once. The
    // extra neckWidth of travel is what lets the trailing edge finish: at
    // progress 1 the front has cleared s = 1 by a full neck.
    float front = progress * (1.0 + neckWidth);

    // Every vertex runs the same collapse, started at a different moment.
    // That offset — and nothing else — is what draws the spout.
    float pull = clamp((front - s) / neckWidth, 0.0, 1.0);
    pull = pull * pull * (3.0 - 2.0 * pull);

    // Across the axis the collapse runs slightly ahead, so the surface is
    // already narrowing before it arrives. Equal rates give a cone; this
    // gives a neck, which is the part that reads as genie.
    float taper = pow(pull, 0.62);

    vec2 pos = qt_Vertex.xy;
    if (horizontal) {
        pos.x = mix(pos.x, targetX, pull);
        pos.y = mix(pos.y, targetY, taper);
    } else {
        pos.x = mix(pos.x, targetX, taper);
        pos.y = mix(pos.y, targetY, pull);
    }

    gl_Position = qt_Matrix * vec4(pos, qt_Vertex.zw);
}

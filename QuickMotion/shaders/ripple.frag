#version 440

// A press spreading outward, masked to the shape it spreads inside.
//
// Drawn rather than clipped. Qt's clipping is always rectangular, so a
// ripple inside a rounded control spills into the corners and squares them
// off — visible on the frame where the wave reaches the edge, and every
// Material control is rounded. Masking with an effect instead would mean a
// texture per control for a shape that is two lines of arithmetic.
//
// Nothing is sampled here: the wave and the mask are both computed, so
// there is no source item, no ShaderEffectSource and nothing to keep in
// sync with the control's size.

layout(location = 0) in vec2 coord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 waveColour;
    float qt_Opacity;
    float itemW;
    float itemH;
    // Corner radius of the control being masked to.
    float rounding;
    // Where the press landed, in item pixels.
    float originX;
    float originY;
    float waveRadius;
    float waveOpacity;
};

void main()
{
    vec2 size = vec2(itemW, itemH);
    vec2 p = coord * size;
    vec2 q = p - size * 0.5;

    // Inside the rounded rectangle.
    float r = min(rounding, min(size.x, size.y) * 0.5);
    vec2 d = abs(q) - (size * 0.5 - vec2(r));
    float box = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
    float inside = 1.0 - smoothstep(-0.75, 0.75, box);

    // Inside the wave. The same half-pixel softness on both edges, so the
    // curve of the wave and the curve of the corner are visibly the same
    // quality rather than one crisp and one ragged.
    float dist = distance(p, vec2(originX, originY));
    float wave = 1.0 - smoothstep(waveRadius - 0.75, waveRadius + 0.75, dist);

    float a = inside * wave * waveOpacity * waveColour.a * qt_Opacity;

    // Premultiplied.
    fragColor = vec4(waveColour.rgb * a, a);
}

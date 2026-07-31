#version 440

layout(location = 0) in vec2 coord;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float targetX;
    float targetY;
    float direction;
    float neckWidth;
};

void main()
{
    // The shape carries the effect; the fade only disposes of what is left
    // once there is nothing recognisable to look at. Fading earlier hides
    // the spout, which is the one thing worth seeing.
    float tail = 1.0 - smoothstep(0.80, 1.0, progress);
    fragColor = texture(source, coord) * qt_Opacity * tail;
}

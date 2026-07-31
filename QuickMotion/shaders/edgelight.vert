#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 coord;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 lightColour;
    vec4 trackColour;
    float qt_Opacity;
    float progress;
    float thickness;
    float rounding;
    float softness;
    float tail;
    float count;
    float glow;
    float itemW;
    float itemH;
    // How far the drawn surface extends beyond the outline it traces, so
    // the halo has somewhere to go. Without it the glow is cut off square
    // at the item bounds, which is far more visible than the glow itself.
    float inset;
};

void main()
{
    coord = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}

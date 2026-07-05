#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gLinearDepth;

// Output: store linear depth into R.
void main() {
    float d = texture2D(gLinearDepth, vUV).r;
    FragColor = vec4(d, d, d, 1.0);
}


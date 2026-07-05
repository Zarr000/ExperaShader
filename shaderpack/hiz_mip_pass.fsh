#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gHiZSrc;

// Mip levels are built by taking the maximum depth in a 2x2 neighborhood.
// This matches typical Hi-Z for occlusion/hierarchical depth traversal.

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    vec2 o = vec2(0.5) * texel;

    float d0 = texture2D(gHiZSrc, vUV + vec2(-o.x, -o.y)).r;
    float d1 = texture2D(gHiZSrc, vUV + vec2( o.x, -o.y)).r;
    float d2 = texture2D(gHiZSrc, vUV + vec2(-o.x,  o.y)).r;
    float d3 = texture2D(gHiZSrc, vUV + vec2( o.x,  o.y)).r;

    float dMax = max(max(d0, d1), max(d2, d3));
    FragColor = vec4(dMax, dMax, dMax, 1.0);
}


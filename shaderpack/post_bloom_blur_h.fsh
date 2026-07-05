#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gBloom;

// Separable Gaussian blur (horizontal)

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    // Fixed 9-tap kernel for stability.
    float w0 = 0.227027;
    float w1 = 0.1945946;
    float w2 = 0.1216216;
    float w3 = 0.054054;
    float w4 = 0.016216;

    vec3 c = texture2D(gBloom, vUV).rgb * w0;
    c += texture2D(gBloom, vUV + vec2(texel.x * 1.0, 0.0)).rgb * w1;
    c += texture2D(gBloom, vUV - vec2(texel.x * 1.0, 0.0)).rgb * w1;
    c += texture2D(gBloom, vUV + vec2(texel.x * 2.0, 0.0)).rgb * w2;
    c += texture2D(gBloom, vUV - vec2(texel.x * 2.0, 0.0)).rgb * w2;
    c += texture2D(gBloom, vUV + vec2(texel.x * 3.0, 0.0)).rgb * w3;
    c += texture2D(gBloom, vUV - vec2(texel.x * 3.0, 0.0)).rgb * w3;
    c += texture2D(gBloom, vUV + vec2(texel.x * 4.0, 0.0)).rgb * w4;
    c += texture2D(gBloom, vUV - vec2(texel.x * 4.0, 0.0)).rgb * w4;

    FragColor = vec4(c, 1.0);
}


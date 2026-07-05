#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;

void main() {
    vec3 hdr = texture2D(gColor, vUV).rgb;

    // Bright-pass extraction.
    float luminance = dot(hdr, vec3(0.2126, 0.7152, 0.0722));
    float t = max(bloomThreshold, 0.0001);
    float mask = saturate((luminance - t) / t);

    vec3 extracted = hdr * mask * bloomIntensity;
    FragColor = vec4(extracted, 1.0);
}


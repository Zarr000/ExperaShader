#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/tonemap.glsl"

in vec2 vUV;

out vec4 FragColor;

uniform sampler2D gColor;

vec3 bloomTone(vec3 hdr) {
    vec3 mapped = acesFilmic(hdr * exposure);
    return mapped;
}

void main() {
    vec3 hdr = texture2D(gColor, vUV).rgb;

    // Basic auto exposure is applied via exposure uniform.
    vec3 ldr = bloomTone(hdr);

    // Gamma correction
    vec3 srgb = linearToSRGB(ldr);
    FragColor = vec4(srgb, 1.0);
}


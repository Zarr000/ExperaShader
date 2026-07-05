#version 150

// Composite pass: apply SSR/volumetrics and final tone mapping.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/tonemap.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gAO;
uniform sampler2D gFogScatter;
uniform sampler2D gFogFactor;
uniform sampler2D gCloudShadow;
uniform sampler2D gSSR;
uniform sampler2D gDepth;

uniform float exposure;

void main() {
    vec3 base = texture2D(gColor, vUV).rgb;

    float ao = texture2D(gAO, vUV).a;
    vec3 fogCol = texture2D(gFogScatter, vUV).rgb;
    float fogFactor = texture2D(gFogFactor, vUV).a;
    float cloudShadow = texture2D(gCloudShadow, vUV).a;

    vec3 ssr = texture2D(gSSR, vUV).rgb;

    // Apply AO.
    vec3 lit = base * ao;

    // SSR mix (weak to stay stable without history).
    lit += ssr * 0.35;

    // Volumetrics.
    lit = mix(lit, fogCol, fogFactor);

    // Cloud shadows.
    lit *= mix(1.0, cloudShadow, 0.75);

    // Tone map.
    vec3 mapped = acesFilmic(lit * exposure);

    // Gamma.
    vec3 srgb = linearToSRGB(mapped);
    FragColor = vec4(srgb, 1.0);
}


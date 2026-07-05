#version 150

// Screen Space Reflections pass.
// Outputs reflection color in RGB and hit factor in A.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/ssr.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gNormalRough;
uniform sampler2D gDepth;

uniform sampler2D gPrevSSR;

uniform sampler2D gWorldPosDepth;

uniform float ssrEnabled;
uniform float ssrQuality;

uniform float time;

vec3 unpackNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

vec3 reflectView(vec3 N, vec3 V) {
    return normalize(reflect(-V, N));
}

void main() {
    vec4 nr = texture2D(gNormalRough, vUV);
    vec3 N = unpackNormal(nr.rgb);
    float roughness = clamp(nr.a, 0.02, 1.0);

    // Water vs rough surface attenuation (very conservative, based on material ID if bound).
    // Here we reuse SSR enable gating; production would use a real material mask.


    // View vector approximation.
    vec3 worldPos = texture2D(gWorldPosDepth, vUV).xyz;
    vec3 V = normalize(vec3(0.0) - worldPos + cameraPosition);

    vec3 rd = reflectView(N, V);

    float enable = step(0.5, ssrEnabled);

    int steps = int(mix(20.0, 64.0, ssrQuality));
    int refine = 6;

    // Use the SSR marcher in a proxy screen-space UV domain.
    // ro/rd treated as directional proxies.
// Use hierarchical depth tex if bound; else fall back to gDepth.
// Current implementation reads depthTex and assumes it matches depth compare space.
vec3 march = ssrRayMarch(vec3(0.0), rd, roughness, gDepth, steps, refine);

    vec2 hitUV = march.xy;
    float hit = march.z;


    vec3 scene = texture2D(gColor, hitUV).rgb;

    // Roughness-aware energy conservation.
    float rFac = mix(0.9, 0.2, roughness);
    vec3 refl = scene * rFac;

    // Temporal accumulation.
    // If we have a hit, prefer current ray; otherwise keep history to avoid flicker.
    vec3 prev = texture2D(gPrevSSR, vUV).rgb;

    float tBlend = taaFeedback;
    float histWeight = mix(1.0, 0.25, hit);
    tBlend = clamp(tBlend * histWeight, 0.02, 0.95);

    // Reflection filtering: slightly blur based on roughness by attenuating SSR strength.
    float roughAtten = mix(1.0, 0.55, roughness * roughness);
    vec3 outCol = mix(refl * roughAtten, prev, (1.0 - hit) * tBlend);



    FragColor = vec4(outCol * enable, hit * enable);
}


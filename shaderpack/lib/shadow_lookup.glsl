#version 150
#ifndef SHADOW_LOOKUP_GLSL
#define SHADOW_LOOKUP_GLSL

#include "common/math.glsl"
#include "common/uniforms.glsl"
#include "shadow_pcss.glsl"
#include "csm.glsl"

// These samplers/matrices are pipeline-specific; we provide conservative defaults.
uniform sampler2D gShadowMap0;
uniform sampler2D gShadowMap1;
uniform sampler2D gShadowMap2;

uniform mat4 shadowProj0;
uniform mat4 shadowProj1;
uniform mat4 shadowProj2;
uniform mat4 shadowView;

uniform vec3 cameraPosition;

uniform vec3 shadowLightDirection;
uniform float shadowEnabled;
uniform float shadowSoftness;
uniform float shadowBiasNormal;
uniform float shadowBiasSlope;
uniform float shadowContactStrength;

float sampleShadowAll(vec4 shadowCoord, sampler2D smap, float bias, float radius, int taps) {
    vec3 sc = shadowCoord.xyz / max(shadowCoord.w, 1e-6);
    vec2 uv = sc.xy * 0.5 + 0.5;
    float depth = sc.z * 0.5 + 0.5;
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 1.0;

    // PCF fallback if PCSS blocker search not wired.
    // Compare: dref <= storedDepth means lit.
    float occ = 0.0;
    for (int i = 0; i < 4; i++) {
        // small rotated jitter based on i
        vec2 off = vec2(float(i) * 0.37, float(i) * -0.21) * radius;
        float sd = texture2D(smap, uv + off).r;
        occ += step(depth - bias, sd);
    }
    occ /= 4.0;
    return occ;
}

float computeShadowFactor(vec3 worldPos, vec3 N, float roughness) {
    float enabled = step(0.5, shadowEnabled);

    // View depth approximation along light opposite.
    float viewDepth = length(worldPos - cameraPosition);
    int cascade = chooseCascade(viewDepth);

    // Project into each cascade.
    vec4 sc0 = shadowProj0 * vec4(worldPos, 1.0);
    vec4 sc1 = shadowProj1 * vec4(worldPos, 1.0);
    vec4 sc2 = shadowProj2 * vec4(worldPos, 1.0);

    float bias = shadowBiasNormal + shadowBiasSlope * (1.0 - saturate(dot(N, -shadowLightDirection)));
    float radius = shadowSoftness;

    float s = 1.0;
    if (cascade == 0) s = sampleShadowAll(sc0, gShadowMap0, bias, radius, 4);
    else if (cascade == 1) s = sampleShadowAll(sc1, gShadowMap1, bias, radius, 4);
    else s = sampleShadowAll(sc2, gShadowMap2, bias, radius, 4);

    // Shadow confidence weighting: soften edges near N.
    float conf = mix(0.6, 1.0, saturate(dot(N, vec3(0.0, 1.0, 0.0))));
    s = mix(1.0, s, conf);

    return mix(1.0, s, enabled);
}

#endif


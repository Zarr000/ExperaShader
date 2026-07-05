#version 150
#ifndef SSR_DEPTH_GLSL
#define SSR_DEPTH_GLSL

#include "common/math.glsl"
#include "common/uniforms.glsl"

float sampleSceneDepth(vec2 uv) {
    return texture2D(gDepth, uv).r;
}

float sampleHiZDepth(vec2 uv) {
    return texture2D(gHiZ, uv).r;
}

float thicknessReject(vec2 uv, float roughness) {
    float dC = texture2D(gHiZ, uv).r;
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));
    float dX = texture2D(gHiZ, uv + vec2(texel.x, 0.0)).r;
    float dY = texture2D(gHiZ, uv + vec2(0.0, texel.y)).r;
    float dd = max(abs(dX - dC), abs(dY - dC));
    return saturate(dd * mix(20.0, 6.0, saturate(roughness)));
}

#endif


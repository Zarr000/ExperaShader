#version 150
#ifndef SHADOW_SAMPLING_GLSL
#define SHADOW_SAMPLING_GLSL

#include "shadow_common.glsl"

uniform sampler2D gShadowMap0;
uniform sampler2D gShadowMap1;
uniform sampler2D gShadowMap2;

float shadowSampleDepth(sampler2D smap, vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 1.0;
    return texture2D(smap, uv).r;
}

float shadowSampleCompare(sampler2D smap, vec2 uv, float compareDepth, float bias) {
    float sampleDepth = shadowSampleDepth(smap, uv);
    return step(compareDepth - bias, sampleDepth);
}

vec3 shadowNdcToUv(vec3 shadowCoord) {
    vec3 scaled = shadowCoord.xyz / max(abs(shadowCoord.z), 1e-6);
    vec2 uv = scaled.xy * 0.5 + 0.5;
    return vec3(uv, scaled.z);
}

#endif

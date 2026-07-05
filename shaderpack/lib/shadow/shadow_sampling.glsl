#version 150
#ifndef SHADOW_SAMPLING_GLSL
#define SHADOW_SAMPLING_GLSL

#include "shadow_common.glsl"

uniform sampler2D gShadowMap0;
uniform sampler2D gShadowMap1;
uniform sampler2D gShadowMap2;

float shadowSampleDepth(sampler2D smap, vec2 uv) {
    return texture2D(smap, uv).r;
}

float shadowSampleCompare(sampler2D smap, vec2 uv, float compareDepth, float bias) {
    float sampleDepth = shadowSampleDepth(smap, uv);
    return step(compareDepth - bias, sampleDepth);
}

#endif

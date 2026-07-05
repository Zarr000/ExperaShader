#version 150
#ifndef SHADOW_FILTER_GLSL
#define SHADOW_FILTER_GLSL

#include "shadow_sampling.glsl"

vec2 shadowPoissonDisk[16] = vec2[16](
    vec2(-0.94201624, -0.39906216), vec2(0.94558609, -0.76890725),
    vec2(-0.094184101, -0.92938870), vec2(0.34495938, 0.29387760),
    vec2(-0.91588581, 0.45771432), vec2(-0.81544232, -0.87912464),
    vec2(-0.38277543, 0.27676845), vec2(0.97484398, 0.75648379),
    vec2(0.44323325, -0.97511554), vec2(0.53742981, -0.47373420),
    vec2(-0.26496911, -0.41893023), vec2(0.79197514, 0.19090188),
    vec2(-0.24188840, 0.99706507), vec2(-0.81409955, 0.91437590),
    vec2(0.19984126, 0.78641367), vec2(0.14383161, -0.14100790)
);

vec2 shadowRotateOffset(vec2 offset, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec2(c * offset.x - s * offset.y, s * offset.x + c * offset.y);
}

float shadowPcf(sampler2D smap, vec2 uv, float compareDepth, float bias, float radius, int taps) {
    float occ = 0.0;
    int count = clamp(taps, 1, 16);
    float angle = fract(sin(float(count) * 12.9898) * 43758.5453) * 6.2831853;

    for (int i = 0; i < 16; i++) {
        if (i >= count) break;
        vec2 offset = shadowRotateOffset(shadowPoissonDisk[i], angle) * radius;
        occ += shadowSampleCompare(smap, uv + offset, compareDepth, bias);
    }

    return occ / float(max(count, 1));
}

float shadowPcss(sampler2D smap, vec2 uv, float compareDepth, float bias, float radius, int taps, float blockerSearchRadius, float lightSize) {
    float blockerDepth = 0.0;
    float blockerCount = 0.0;
    int count = clamp(taps / 2, 2, 8);

    for (int i = 0; i < 16; i++) {
        if (i >= count) break;
        vec2 offset = shadowPoissonDisk[i] * blockerSearchRadius;
        float sampleDepth = shadowSampleDepth(smap, uv + offset);
        if (sampleDepth < compareDepth - bias) {
            blockerDepth += sampleDepth;
            blockerCount += 1.0;
        }
    }

    if (blockerCount <= 0.0) {
        return shadowPcf(smap, uv, compareDepth, bias, radius, taps);
    }

    float blockerAvg = blockerDepth / max(blockerCount, 1.0);
    float penumbra = max((compareDepth - blockerAvg) * lightSize, 0.0);
    float adaptedRadius = radius + penumbra * 0.35;
    return shadowPcf(smap, uv, compareDepth, bias, adaptedRadius, taps);
}

#endif

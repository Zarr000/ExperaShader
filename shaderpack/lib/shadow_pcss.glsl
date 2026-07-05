#version 150
#ifndef SHADOW_PCSS_GLSL
#define SHADOW_PCSS_GLSL

// PCSS-style shadow filtering helpers (original implementation).

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

uniform sampler2D gShadowMap;

// Shadow sampling (depth in [0,1]).
float sampleShadowDepth(vec2 uv) {
    return texture2D(gShadowMap, uv).r;
}

// Receiver bias based on slope/normal rough proxy.
float receiverBias(float ndv, float normalLen, float roughness) {
    float nBias = mix(0.0008, 0.003, 1.0 - saturate(ndv));
    float sBias = mix(0.0002, 0.002, normalLen);
    float rBias = mix(0.0001, 0.0025, roughness);
    return nBias + sBias + rBias;
}

// Penumbra estimation: ratio of blocker depth difference.
float estimatePenumbra(float receiverDepth, float blockerDepth, float lightSize) {
    float z = max(receiverDepth - blockerDepth, 0.0);
    return z * lightSize;
}

// PCF with Poisson disk samples.
vec2 poissonDisk[16] = vec2[16](
    vec2(-0.94201624, -0.39906216), vec2(0.94558609, -0.76890725),
    vec2(-0.094184101, -0.92938870), vec2(0.34495938, 0.29387760),
    vec2(-0.91588581, 0.45771432), vec2(-0.81544232, -0.87912464),
    vec2(-0.38277543, 0.27676845), vec2(0.97484398, 0.75648379),
    vec2(0.44323325, -0.97511554), vec2(0.53742981, -0.47373420),
    vec2(-0.26496911, -0.41893023), vec2(0.79197514, 0.19090188),
    vec2(-0.24188840, 0.99706507), vec2(-0.81409955, 0.91437590),
    vec2(0.19984126, 0.78641367), vec2(0.14383161, -0.14100790)
);

float pcfShadow(vec2 uv, float compareDepth, float bias, float radius, int taps) {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));
    // radius is in shadow map UV units.
    float occ = 0.0;
    int t = min(taps, 16);

    for (int i = 0; i < 16; i++) {
        if (i >= t) break;
        vec2 o = poissonDisk[i] * radius;
        float d = sampleShadowDepth(uv + o);
        occ += step(compareDepth - bias, d);
    }

    return occ / float(max(t, 1));
}

#endif


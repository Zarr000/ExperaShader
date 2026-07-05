#version 150
#ifndef SHADOW_QUALITY_GLSL
#define SHADOW_QUALITY_GLSL

#include "shadow_common.glsl"

float shadowQualityPreset(float quality) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= SHADOW_QUALITY_PERFORMANCE) return 3.0;
    if (q <= SHADOW_QUALITY_BALANCED) return 5.0;
    if (q <= SHADOW_QUALITY_HIGH) return 7.0;
    if (q <= SHADOW_QUALITY_ULTRA) return 9.0;
    return 11.0;
}

vec3 shadowPresetConfig(float quality) {
    float samples = shadowQualityPreset(quality);
    float pcf = mix(3.0, 7.0, clamp(quality / 4.0, 0.0, 1.0));
    float pcss = mix(0.0, 1.0, clamp(quality / 4.0, 0.0, 1.0));
    return vec3(samples, pcf, pcss);
}

#endif

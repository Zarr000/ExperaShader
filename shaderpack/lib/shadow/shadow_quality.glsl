#version 150
#ifndef SHADOW_QUALITY_GLSL
#define SHADOW_QUALITY_GLSL

#include "shadow_common.glsl"

float shadowQualityPreset(float quality) {
    if (quality <= SHADOW_QUALITY_PERFORMANCE) return 1.0;
    if (quality <= SHADOW_QUALITY_BALANCED) return 2.0;
    if (quality <= SHADOW_QUALITY_HIGH) return 4.0;
    if (quality <= SHADOW_QUALITY_ULTRA) return 6.0;
    return 8.0;
}

vec3 shadowPresetConfig(float quality) {
    float samples = shadowQualityPreset(quality);
    float pcf = mix(2.0, 6.0, clamp(quality / 4.0, 0.0, 1.0));
    float pcss = mix(0.0, 1.0, clamp(quality / 4.0, 0.0, 1.0));
    return vec3(samples, pcf, pcss);
}

#endif

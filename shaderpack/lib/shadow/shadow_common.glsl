#version 150
#ifndef SHADOW_COMMON_GLSL
#define SHADOW_COMMON_GLSL

#include "../common/math.glsl"

#define SHADOW_QUALITY_PERFORMANCE 0.0
#define SHADOW_QUALITY_BALANCED    1.0
#define SHADOW_QUALITY_HIGH        2.0
#define SHADOW_QUALITY_ULTRA       3.0
#define SHADOW_QUALITY_EXTREME     4.0

struct ShadowCascadeData {
    mat4 projection;
    mat4 view;
    vec4 split;
    float texelSize;
};

float shadowQualityScale(float quality, float low, float mid, float high, float ultra) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= SHADOW_QUALITY_PERFORMANCE) return low;
    if (q <= SHADOW_QUALITY_BALANCED) return mid;
    if (q <= SHADOW_QUALITY_HIGH) return high;
    if (q <= SHADOW_QUALITY_ULTRA) return ultra;
    return ultra + 0.5;
}

#endif

#version 150
#ifndef RENDERER_QUALITY_GLSL
#define RENDERER_QUALITY_GLSL

#include "renderer_common.glsl"

// Quality presets for renderer-wide scaling

float rendererQualityScale(float quality, float perf, float balanced, float high, float ultra, float extreme) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= RENDERER_PERFORMANCE) return perf;
    if (q <= RENDERER_BALANCED) return mix(perf, balanced, q - RENDERER_PERFORMANCE);
    if (q <= RENDERER_HIGH) return mix(balanced, high, q - RENDERER_BALANCED);
    if (q <= RENDERER_ULTRA) return mix(high, ultra, q - RENDERER_HIGH);
    return mix(ultra, extreme, q - RENDERER_ULTRA);
}

// Quality-scaled pass enablement
float rendererPassQuality(float quality) {
    return quality;
}

// Quality-scaled history length
float rendererHistoryLength(float quality) {
    return rendererQualityScale(quality, 1.0, 2.0, 3.0, 4.0, 5.0);
}

// Quality-scaled temporal quality
float rendererTemporalQuality(float quality) {
    return rendererQualityScale(quality, 0.5, 0.7, 0.85, 0.95, 1.0);
}

// Quality-scaled debug overhead
float rendererDebugOverhead(float quality) {
    return rendererQualityScale(quality, 0.0, 0.1, 0.3, 0.5, 1.0);
}

#endif
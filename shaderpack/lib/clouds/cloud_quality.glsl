#version 150
#ifndef CLOUD_QUALITY_GLSL
#define CLOUD_QUALITY_GLSL

#include "cloud_common.glsl"

// Cloud quality presets and scaling functions
// Maps cloudsQuality uniform to specific rendering parameters

// Get cloud quality level from uniform
float cloudGetQualityLevel() {
    return clamp(cloudsQuality, 0.0, 4.0);
}

// Compute cloud quality scale factor for a given preset range
float cloudQualityScale(float quality, float perf, float balanced, float high, float ultra, float extreme) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= CLOUD_PERFORMANCE) return perf;
    if (q <= CLOUD_BALANCED) return mix(perf, balanced, q - CLOUD_PERFORMANCE);
    if (q <= CLOUD_HIGH) return mix(balanced, high, q - CLOUD_BALANCED);
    if (q <= CLOUD_ULTRA) return mix(high, ultra, q - CLOUD_HIGH);
    return mix(ultra, extreme, q - CLOUD_ULTRA);
}

// Quality-scaled raymarch steps
float cloudQualitySteps(float quality) {
    return cloudQualityScale(quality, 16.0, 32.0, 48.0, 64.0, 96.0);
}

// Quality-scaled shadow steps
float cloudQualityShadowSteps(float quality) {
    return cloudQualityScale(quality, 4.0, 6.0, 8.0, 10.0, 12.0);
}

// Quality-scaled noise octaves
float cloudQualityNoiseOctaves(float quality) {
    return cloudQualityScale(quality, 3.0, 4.0, 5.0, 6.0, 7.0);
}

// Quality-scaled detail octaves
float cloudQualityDetailOctaves(float quality) {
    return cloudQualityScale(quality, 2.0, 3.0, 4.0, 5.0, 6.0);
}

// Quality-scaled temporal feedback
float cloudQualityTemporalFeedback(float quality) {
    return cloudQualityScale(quality, 0.7, 0.8, 0.85, 0.9, 0.93);
}

// Quality-scaled step size
float cloudQualityStepSize(float quality) {
    return cloudQualityScale(quality, 8.0, 6.0, 4.0, 3.0, 2.0);
}

// Determine if clouds should be rendered at all
bool cloudShouldRender(float quality) {
    return quality >= CLOUD_PERFORMANCE && cloudsEnabled > 0.5;
}

#endif
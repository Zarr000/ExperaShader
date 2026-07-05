#version 150
#ifndef WATER_QUALITY_GLSL
#define WATER_QUALITY_GLSL

#include "water_common.glsl"

// Water quality presets and scaling

// Quality-scaled wave complexity
float waterQualityWaveComplexity(float quality) {
    return waterQualityScale(quality, 2.0, 3.0, 4.0, 4.0, 4.0);
}

// Quality-scaled SSR quality
float waterQualitySSRQuality(float quality) {
    return waterQualityScale(quality, 0.3, 0.6, 0.8, 1.0, 1.0);
}

// Quality-scaled refraction quality
float waterQualityRefractionQuality(float quality) {
    return waterQualityScale(quality, 0.4, 0.7, 0.9, 1.0, 1.0);
}

// Quality-scaled caustic quality
float waterQualityCausticQuality(float quality) {
    return waterQualityScale(quality, 0.3, 0.6, 0.8, 1.0, 1.0);
}

// Quality-scaled foam quality
float waterQualityFoamQuality(float quality) {
    return waterQualityScale(quality, 0.5, 0.7, 0.85, 1.0, 1.0);
}

// Quality-scaled underwater quality
float waterQualityUnderwaterQuality(float quality) {
    return waterQualityScale(quality, 0.4, 0.6, 0.8, 1.0, 1.0);
}

#endif
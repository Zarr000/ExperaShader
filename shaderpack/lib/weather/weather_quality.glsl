#version 150
#ifndef WEATHER_QUALITY_GLSL
#define WEATHER_QUALITY_GLSL

#include "weather_common.glsl"

// Weather quality presets and scaling

// Quality-scaled simulation update frequency
float weatherQualityUpdateFrequency(float quality) {
    return weatherQualityScale(quality, 0.5, 1.0, 2.0, 4.0, 8.0);
}

// Quality-scaled wind simulation detail
float weatherQualityWindDetail(float quality) {
    return weatherQualityScale(quality, 0.3, 0.5, 0.7, 0.9, 1.0);
}

// Quality-scaled transition precision
float weatherQualityTransitionPrecision(float quality) {
    return weatherQualityScale(quality, 0.5, 0.7, 0.85, 0.95, 1.0);
}

// Quality-scaled fog quality
float weatherQualityFogQuality(float quality) {
    return weatherQualityScale(quality, 0.4, 0.6, 0.8, 0.95, 1.0);
}

// Quality-scaled wetness precision
float weatherQualityWetnessPrecision(float quality) {
    return weatherQualityScale(quality, 0.3, 0.5, 0.7, 0.9, 1.0);
}

// Determine if detailed weather simulation should run
bool weatherDetailedSimulation(float quality) {
    return quality >= WEATHER_BALANCED;
}

#endif
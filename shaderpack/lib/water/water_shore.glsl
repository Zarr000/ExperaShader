#version 150
#ifndef WATER_SHORE_GLSL
#define WATER_SHORE_GLSL

#include "water_common.glsl"
#include "water_foam.glsl"

// Shore-specific water effects
// Distance to shore, shore foam, shallow water color, wetness

// Shore distance factor (0 at shore, 1 away from shore)
float waterShoreDistance(float dist, float shoreWidth) {
    return saturate(dist / shoreWidth);
}

// Shallow water color blending
vec3 waterShallowColor(float shoreDist, vec3 shallowColor, vec3 deepColor, float shoreWidth) {
    float factor = 1.0 - waterShoreDistance(shoreDist, shoreWidth);
    return mix(deepColor, shallowColor, factor);
}

// Shore wetness (terrain near shore gets wet)
float waterShoreWetness(float shoreDist, float shoreWidth, float wetness) {
    float shoreFactor = 1.0 - saturate(shoreDist / shoreWidth);
    return wetness * shoreFactor * 0.5;
}

#endif
#version 150
#ifndef WATER_ABSORPTION_GLSL
#define WATER_ABSORPTION_GLSL

#include "water_common.glsl"

// Beer-Lambert water absorption model
// Depth-dependent color with water color presets

// Beer-Lambert absorption
vec3 waterBeerLambert(vec3 absorptionCoeff, float distance) {
    return exp(-absorptionCoeff * distance);
}

// Water color at depth
vec3 waterColorAtDepth(float depth, vec3 shallowColor, vec3 deepColor, vec3 absorptionCoeff) {
    vec3 absorption = waterBeerLambert(absorptionCoeff, depth);
    return mix(deepColor, shallowColor, absorption);
}

// Visibility attenuation through water
float waterVisibilityAtDepth(float depth, float maxVisibility) {
    return exp(-depth / max(maxVisibility, 0.1));
}

// Compute water surface albedo from depth and color
vec3 waterSurfaceAlbedo(float depth, vec3 shallowColor, vec3 deepColor, vec3 absorptionCoeff) {
    vec3 color = waterColorAtDepth(depth, shallowColor, deepColor, absorptionCoeff);
    // Water base albedo is very low (mostly transmissive)
    return color * 0.05;
}

#endif
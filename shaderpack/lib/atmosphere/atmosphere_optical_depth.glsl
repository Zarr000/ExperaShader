#version 150
#ifndef ATMOSPHERE_OPTICAL_DEPTH_GLSL
#define ATMOSPHERE_OPTICAL_DEPTH_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_density.glsl"

vec3 atmosphereOpticalDepth(float height, vec3 scaleHeight, float sampleCount) {
    float h = max(height, 0.0);
    vec3 density = vec3(
        atmosphereDensity(h, scaleHeight.r),
        atmosphereDensity(h, scaleHeight.g),
        atmosphereDensity(h, scaleHeight.b)
    );
    return density * sampleCount * 0.001;
}

#endif

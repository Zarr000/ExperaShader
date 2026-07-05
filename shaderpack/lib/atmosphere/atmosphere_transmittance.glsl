#version 150
#ifndef ATMOSPHERE_TRANSMITTANCE_GLSL
#define ATMOSPHERE_TRANSMITTANCE_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_optical_depth.glsl"

// Runtime-driven atmospheric transmittance
// Computes how much light penetrates the atmosphere at a given height

vec3 atmosphereTransmittance(
    float height,
    vec3 scaleHeights,
    float sampleCount,
    AtmosphereRuntime r
) {
    vec3 opticalDepth = atmosphereOpticalDepth(height, scaleHeights, sampleCount, r);
    return exp(-opticalDepth * max(r.weatherIntensity * 0.5, 1.0));
}

// Transmittance along a ray through the atmosphere
vec3 atmosphereTransmittanceAlongRay(
    vec3 origin,
    vec3 direction,
    float tMin,
    float tMax,
    vec3 scaleHeights,
    float sampleCount,
    AtmosphereRuntime r
) {
    vec3 opticalDepth = atmosphereOpticalDepthAlongRay(
        origin, direction, tMin, tMax, scaleHeights, sampleCount, r
    );
    return exp(-opticalDepth);
}

#endif

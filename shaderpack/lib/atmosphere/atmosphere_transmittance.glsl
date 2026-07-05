#version 150
#ifndef ATMOSPHERE_TRANSMITTANCE_GLSL
#define ATMOSPHERE_TRANSMITTANCE_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_optical_depth.glsl"

vec3 atmosphereTransmittance(float height, vec3 scatteringScaleHeight, float sampleCount) {
    return exp(-atmosphereOpticalDepth(height, scatteringScaleHeight, sampleCount));
}

#endif

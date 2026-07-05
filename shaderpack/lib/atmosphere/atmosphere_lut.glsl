#version 150
#ifndef ATMOSPHERE_LUT_GLSL
#define ATMOSPHERE_LUT_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_transmittance.glsl"

vec3 atmosphereTransmittanceLUT(float height, float quality) {
    return atmosphereTransmittance(height, vec3(8.0, 1.2, 0.8), 1.0 + quality);
}

vec3 atmosphereSkyLUT(float height, float cosTheta, float quality) {
    float h = max(height, 0.0);
    return vec3(0.2, 0.35, 0.55) * (0.4 + 0.6 * quality) * exp(-h * 0.01) * (0.5 + 0.5 * cosTheta);
}

#endif

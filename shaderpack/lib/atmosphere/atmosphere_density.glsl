#version 150
#ifndef ATMOSPHERE_DENSITY_GLSL
#define ATMOSPHERE_DENSITY_GLSL

#include "atmosphere_common.glsl"

float atmosphereDensityHeight(float h, float scaleHeight) {
    return exp(-max(h, 0.0) / max(scaleHeight, 1e-4));
}

float atmosphereDensity(float altitude, float scaleHeight) {
    return atmosphereDensityHeight(max(altitude, 0.0), scaleHeight);
}

#endif

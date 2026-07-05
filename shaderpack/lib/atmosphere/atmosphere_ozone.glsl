#version 150
#ifndef ATMOSPHERE_OZONE_GLSL
#define ATMOSPHERE_OZONE_GLSL

#include "atmosphere_common.glsl"

vec3 atmosphereOzoneAbsorption(float altitude, vec3 ozoneAbsorption, float scaleHeight) {
    float h = max(altitude, 0.0);
    float density = exp(-h / max(scaleHeight, 1e-4));
    return ozoneAbsorption * density;
}

#endif

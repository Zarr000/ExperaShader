#version 150
#ifndef ATMOSPHERE_RAYLEIGH_GLSL
#define ATMOSPHERE_RAYLEIGH_GLSL

#include "atmosphere_common.glsl"

vec3 atmosphereRayleighPhase(float cosTheta) {
    float c = clamp(cosTheta, -1.0, 1.0);
    return vec3(0.75 * (1.0 + c * c));
}

vec3 atmosphereRayleighScatter(AtmosphereParameters p, float cosTheta) {
    return p.rayleighScattering * atmosphereRayleighPhase(cosTheta);
}

#endif

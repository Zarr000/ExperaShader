#version 150
#ifndef ATMOSPHERE_MIE_GLSL
#define ATMOSPHERE_MIE_GLSL

#include "atmosphere_common.glsl"

float atmosphereMiePhase(float g, float cosTheta) {
    float denom = 1.0 + g * g - 2.0 * g * cosTheta;
    return (1.0 - g * g) / (4.0 * 3.14159265 * denom * sqrt(max(denom, 1e-6)));
}

vec3 atmosphereMieScatter(AtmosphereParameters p, float cosTheta) {
    return p.mieScattering * atmosphereMiePhase(p.mieG, cosTheta);
}

#endif

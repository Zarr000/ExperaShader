#version 150
#ifndef ATMOSPHERE_MIE_GLSL
#define ATMOSPHERE_MIE_GLSL

#include "atmosphere_common.glsl"

// Mie phase function (Henyey-Greenstein approximation)
float atmosphereMiePhase(float g, float cosTheta) {
    float denom = 1.0 + g * g - 2.0 * g * cosTheta;
    return (1.0 - g * g) / (4.0 * ATMOSPHERE_PI * denom * sqrt(max(denom, 1e-6)));
}

// Mie scattering coefficient
vec3 atmosphereMieScatter(AtmosphereParameters p, float cosTheta) {
    return p.mieScattering * atmosphereMiePhase(p.mieG, cosTheta);
}

// Mie extinction for altitude
vec3 atmosphereMieExtinction(float h, AtmosphereParameters p) {
    float density = atmosphereDensityHeight(h, p.mieScaleHeight);
    return p.mieExtinction * density;
}

#endif

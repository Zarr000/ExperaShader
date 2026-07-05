#version 150
#ifndef ATMOSPHERE_MULTISCATTER_GLSL
#define ATMOSPHERE_MULTISCATTER_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"

vec3 atmosphereMultiScatter(AtmosphereParameters p, float cosTheta, float quality) {
    vec3 rayleigh = atmosphereRayleighScatter(p, cosTheta) * (0.25 + 0.75 * quality);
    vec3 mie = atmosphereMieScatter(p, cosTheta) * (0.1 + 0.2 * quality);
    return rayleigh + mie;
}

#endif

#version 150
#ifndef ATMOSPHERE_SUN_GLSL
#define ATMOSPHERE_SUN_GLSL

#include "atmosphere_common.glsl"

vec3 atmosphereSunRadiance(vec3 sunDir, vec3 viewDir, float elevation, float limbSoftening) {
    float cosTheta = clamp(dot(sunDir, viewDir), -1.0, 1.0);
    float disc = smoothstep(0.999 - limbSoftening, 1.0, cosTheta);
    float sunset = smoothstep(-0.2, 0.35, elevation);
    return vec3(disc * (0.6 + 0.4 * sunset));
}

#endif

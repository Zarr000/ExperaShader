#version 150
#ifndef ATMOSPHERE_MOON_GLSL
#define ATMOSPHERE_MOON_GLSL

#include "atmosphere_common.glsl"

vec3 atmosphereMoonRadiance(vec3 moonDir, vec3 viewDir, float elevation, float phase) {
    float cosTheta = clamp(dot(moonDir, viewDir), -1.0, 1.0);
    float glow = smoothstep(0.95, 1.0, cosTheta);
    float night = smoothstep(-0.25, 0.2, elevation);
    return vec3(glow * (0.08 + 0.04 * phase) * night);
}

#endif

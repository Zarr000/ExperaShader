#version 150
#ifndef ATMOSPHERE_STARS_GLSL
#define ATMOSPHERE_STARS_GLSL

#include "atmosphere_common.glsl"

vec3 atmosphereStars(float elevation, float intensity) {
    float night = smoothstep(-0.15, 0.1, elevation);
    return vec3(0.02, 0.03, 0.05) * night * intensity;
}

#endif

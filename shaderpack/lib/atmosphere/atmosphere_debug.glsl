#version 150
#ifndef ATMOSPHERE_DEBUG_GLSL
#define ATMOSPHERE_DEBUG_GLSL

#include "atmosphere_common.glsl"

vec3 atmosphereDebugColor(float mode, vec3 value) {
    if (mode < 1.0) return value;
    if (mode < 2.0) return vec3(value.r);
    if (mode < 3.0) return vec3(value.g);
    return vec3(value.b);
}

#endif

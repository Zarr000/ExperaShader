#version 150
#ifndef MOTION_VECTORS_GLSL
#define MOTION_VECTORS_GLSL

#include "common/math.glsl"

vec2 velocityFromClip(vec4 currClip, vec4 prevClip) {
    vec3 currNDC = currClip.xyz / max(currClip.w, 1e-6);
    vec3 prevNDC = prevClip.xyz / max(prevClip.w, 1e-6);
    vec2 currUV = currNDC.xy * 0.5 + 0.5;
    vec2 prevUV = prevNDC.xy * 0.5 + 0.5;
    return currUV - prevUV;
}

#endif


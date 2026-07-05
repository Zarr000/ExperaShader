#version 150
#ifndef SHADOW_CASCADE_GLSL
#define SHADOW_CASCADE_GLSL

#include "shadow_common.glsl"

uniform vec3 csmSplitSums;
uniform vec3 shadowLightDirection;
uniform mat4 shadowProj0;
uniform mat4 shadowProj1;
uniform mat4 shadowProj2;
uniform mat4 shadowView;

int shadowChooseCascade(float viewDepth) {
    if (viewDepth < csmSplitSums.x) return 0;
    if (viewDepth < csmSplitSums.y) return 1;
    return 2;
}

vec4 shadowProjectCascade(vec4 worldPos, mat4 projection, mat4 view) {
    return projection * view * worldPos;
}

float shadowCascadeBlend(float depth, float split0, float split1) {
    float a = smoothstep(split0, split1, depth);
    return clamp(a, 0.0, 1.0);
}

#endif

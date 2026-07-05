#version 150
#ifndef SHADOW_CONTACT_GLSL
#define SHADOW_CONTACT_GLSL

#include "shadow_common.glsl"
#include "../material/material_data.glsl"

float shadowContactMask(vec2 uv, float depth, float thickness, float fade) {
    float sampleDepth = depth;
    float d = abs(sampleDepth - depth);
    return smoothstep(0.0, thickness, 1.0 - d) * fade;
}

float shadowMaterialAware(float materialMask, float contactStrength) {
    return mix(1.0, materialMask, contactStrength);
}

#endif

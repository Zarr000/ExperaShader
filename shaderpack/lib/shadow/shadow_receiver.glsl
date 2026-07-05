#version 150
#ifndef SHADOW_RECEIVER_GLSL
#define SHADOW_RECEIVER_GLSL

#include "shadow_common.glsl"

float shadowReceiverBias(float ndl, float roughness, float normalScale) {
    float slope = max(1.0 - ndl, 0.0);
    float baseBias = mix(0.0008, 0.0030, roughness);
    float slopeBias = slope * 0.0015 * normalScale;
    return baseBias + slopeBias;
}

float shadowReceiverFade(float distance, float maxDistance) {
    return clamp(1.0 - distance / maxDistance, 0.0, 1.0);
}

#endif

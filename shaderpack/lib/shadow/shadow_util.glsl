#version 150
#ifndef SHADOW_UTIL_GLSL
#define SHADOW_UTIL_GLSL

#include "shadow_common.glsl"
#include "shadow_cascade.glsl"
#include "shadow_receiver.glsl"
#include "shadow_filter.glsl"
#include "shadow_contact.glsl"
#include "shadow_color.glsl"
#include "shadow_quality.glsl"

uniform float shadowEnabled;
uniform float shadowQuality;
uniform float shadowSoftness;
uniform float shadowBiasNormal;
uniform float shadowBiasSlope;
uniform float contactShadowEnabled;
uniform float contactShadowStrength;
uniform float shadowMaxDistance;
uniform vec3 cameraPosition;

float shadowComputeMask(vec3 worldPos, vec3 normal, float roughness, float materialMask) {
    float enabled = step(0.5, shadowEnabled);
    float quality = clamp(shadowQuality, 0.0, 4.0);
    float ndl = saturate(dot(normal, -shadowLightDirection));
    float bias = shadowReceiverBias(ndl, roughness, 1.0);
    float fade = shadowReceiverFade(length(worldPos - cameraPosition), shadowMaxDistance);
    float mask = 1.0;
    if (enabled > 0.5) {
        mask = mix(1.0, 0.75, quality * 0.1);
    }
    mask *= fade;
    mask *= shadowMaterialAware(materialMask, contactShadowStrength);
    return clamp(mask, 0.0, 1.0);
}

#endif

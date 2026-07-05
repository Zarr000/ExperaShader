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
#include "../common/uniforms.glsl"

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
    if (enabled <= 0.5) return 1.0;

    float quality = clamp(shadowQuality, 0.0, 4.0);
    float ndl = saturate(dot(normal, -shadowLightDirection));
    float bias = shadowReceiverBias(ndl, roughness, 1.0) + shadowBiasNormal + shadowBiasSlope * (1.0 - ndl);
    float dist = length(worldPos - cameraPosition);
    float fade = shadowReceiverFade(dist, shadowMaxDistance);
    if (fade <= 0.0) return 1.0;

    int cascade = shadowChooseCascade(dist);
    mat4 projection = (cascade == 0) ? shadowProj0 : ((cascade == 1) ? shadowProj1 : shadowProj2);
    vec4 shadowCoord = shadowProjectCascade(vec4(worldPos, 1.0), projection, shadowView);
    vec3 projected = shadowNdcToUv(shadowCoord.xyz / max(shadowCoord.w, 1e-6));
    vec2 uv = projected.xy;
    float receiverDepth = projected.z;

    float shadow = 1.0;
    if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0 && receiverDepth >= 0.0) {
        sampler2D smap = (cascade == 0) ? gShadowMap0 : ((cascade == 1) ? gShadowMap1 : gShadowMap2);
        float radius = shadowSoftness * shadowQualityScale(quality, 0.0015, 0.0025, 0.0040, 0.0060);
        int taps = int(shadowQualityPreset(quality));
        float pcf = shadowPcf(smap, uv, receiverDepth, bias, radius, taps);
        float pcss = shadowPcss(smap, uv, receiverDepth, bias, radius, taps, radius * 2.5, mix(0.05, 0.2, quality / 4.0));
        shadow = mix(pcf, pcss, clamp(quality / 4.0, 0.0, 1.0));
    }

    float contact = 1.0;
    if (contactShadowEnabled > 0.5) {
        contact = shadowContactShadows(uv, worldPos, normal, -shadowLightDirection, receiverDepth, 0.01, fade, contactShadowStrength);
    }

    float mask = mix(1.0, shadow * contact, fade * ndl);
    mask *= shadowMaterialAware(materialMask, contactShadowStrength);
    return clamp(mask, 0.0, 1.0);
}

#endif

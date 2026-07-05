#version 150
#ifndef SHADOW_CONTACT_GLSL
#define SHADOW_CONTACT_GLSL

#include "shadow_common.glsl"
#include "../material/material_data.glsl"
#include "../common/uniforms.glsl"

float shadowContactMask(vec2 uv, float depth, float thickness, float fade) {
    float sampleDepth = depth;
    float d = abs(sampleDepth - depth);
    return smoothstep(0.0, thickness, 1.0 - d) * fade;
}

float shadowMaterialAware(float materialMask, float contactStrength) {
    return mix(1.0, materialMask, contactStrength);
}

float shadowContactShadows(vec2 uv, vec3 worldPos, vec3 normal, vec3 lightDir, float receiverDepth, float thickness, float fade, float strength) {
    if (strength <= 0.0 || fade <= 0.0) return 1.0;

    vec3 marchDir = normalize(lightDir + normal * 0.025);
    vec3 samplePos = worldPos + marchDir * 0.01;
    float shadow = 1.0;

    for (int i = 0; i < 4; i++) {
        vec4 clip = currentViewProjection * vec4(samplePos, 1.0);
        vec3 ndc = clip.xyz / max(clip.w, 1e-6);
        vec2 sampleUV = ndc.xy * 0.5 + 0.5;
        float ndcDepth = ndc.z * 0.5 + 0.5;

        if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
            float sceneDepth = texture2D(gDepth, sampleUV).r;
            if (sceneDepth > 0.0 && sceneDepth < ndcDepth) {
                float occlusion = smoothstep(0.0, thickness, ndcDepth - sceneDepth);
                shadow = min(shadow, mix(1.0, 0.2, occlusion * strength));
            }
        }

        samplePos += marchDir * 0.012 * float(i + 1);
    }

    return mix(1.0, shadow, fade);
}

#endif

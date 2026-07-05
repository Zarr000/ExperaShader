#version 150

// Screen Space Reflections pass.
// Outputs reflection color in RGB and hit factor in A.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/ssr.glsl"
#include "lib/material/material_data.glsl"
#include "lib/material/material_decode.glsl"
#include "lib/renderer/renderer_ssr_optimizer.glsl"
#include "lib/renderer/renderer_quality.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gNormalRough;
uniform sampler2D gDepth;

uniform sampler2D gPrevSSR;

uniform sampler2D gWorldPosDepth;

uniform float ssrEnabled;
uniform float ssrQuality;

uniform float time;

vec3 reflectView(vec3 N, vec3 V) {
    return normalize(reflect(-V, N));
}

void main() {
    vec4 nr = texture2D(gNormalRough, vUV);
    MaterialData material = materialDecodeFromNormalRough(nr);
    vec3 N = material.normal;
    float roughness = material.roughness;

    // View vector approximation.
    vec3 worldPos = texture2D(gWorldPosDepth, vUV).xyz;
    vec3 V = normalize(vec3(0.0) - worldPos + cameraPosition);

    vec3 rd = reflectView(N, V);

    float enable = step(0.5, ssrEnabled);

    // Initialize SSR optimization state with quality
    SSROptimizationState ssrOpt = rendererSSROptimizerInit(ssrQuality);
    
    // Adaptive steps based on quality and roughness
    int adaptiveSteps = int(rendererSSRAdaptiveRays(roughness, ssrOpt));
    int adaptiveRefine = int(ssrOpt.adaptiveSearchIterations);
    
    // Use the SSR marcher with optimization state
    vec3 march = ssrRayMarch(vec3(0.0), rd, roughness, gDepth, adaptiveSteps, adaptiveRefine, ssrOpt);


    vec2 hitUV = march.xy;
    float hit = march.z;


    vec3 scene = texture2D(gColor, hitUV).rgb;

    // Roughness-aware energy conservation.
    float rFac = mix(0.9, 0.2, roughness);
    vec3 refl = scene * rFac;

    // Temporal accumulation.
    // If we have a hit, prefer current ray; otherwise keep history to avoid flicker.
    vec3 prev = texture2D(gPrevSSR, vUV).rgb;

    float tBlend = taaFeedback;
    float histWeight = mix(1.0, 0.25, hit);
    tBlend = clamp(tBlend * histWeight, 0.02, 0.95);

    // Reflection confidence weighting.
    // - Higher roughness reduces confidence.
    // - Higher hit factor increases confidence.
    float viewAngle = saturate(dot(normalize(N), normalize(-V)));
    float angleFade = mix(1.0, 0.2, pow(1.0 - viewAngle, 2.0));

    // Roughness blur approximation: reduce SSR contribution and increase history reliance.
    float roughBlur = mix(1.0, 0.45, roughness * roughness);

    // Neighborhood clamping to reduce temporal flicker/leaks.
    // (Sampling a 3x3 neighborhood around hit UV and clamping to local min/max.)
    vec3 nMin = scene;
    vec3 nMax = scene;
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    for (int oy = -1; oy <= 1; oy++) {
        for (int ox = -1; ox <= 1; ox++) {
            vec2 o = vec2(float(ox), float(oy)) * texel;
            vec3 s = texture2D(gColor, hitUV + o).rgb;
            nMin = min(nMin, s);
            nMax = max(nMax, s);
        }
    }

    vec3 ssrColor = clamp(refl * roughBlur, nMin, nMax);

    // Temporal reprojection improvement: rejection if history deviates too far.
    float historyErr = length(ssrColor - prev);
    float validHist = step(historyErr, mix(0.25, 0.08, hit));
    vec3 hist = mix(prev, ssrColor, 1.0 - validHist);

    float confidence = hit * angleFade * mix(1.0, 0.55, roughness);
    float blend = saturate(tBlend * (1.0 - confidence));

    vec3 outCol = mix(ssrColor, hist, blend);




    // Reflection validity tests + hole filling.
    // If no hit: keep output conservative by falling back to zero (composite handles sky/fallback).
    float validity = step(0.01, hit);
    vec3 finalRefl = outCol * validity;

    // Better edge handling: already included in hit.
    FragColor = vec4(finalRefl * enable, validity * hit * enable);

}


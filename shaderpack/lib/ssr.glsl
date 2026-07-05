#version 150
#ifndef SSR_GLSL
#define SSR_GLSL

#include "common/math.glsl"
#include "common/uniforms.glsl"
#include "ssr_depth.glsl"
#include "renderer/renderer_ssr_optimizer.glsl"
#include "renderer/renderer_ssr_cache.glsl"
#include "renderer/renderer_ssr_statistics.glsl"
#include "renderer/renderer_sampling.glsl"

float saturate01(float x) { return saturate(x); }

float edgeFade(vec2 uv) {
    vec2 p = abs(uv * 2.0 - 1.0);
    float m = max(p.x, p.y);
    return saturate(1.0 - smoothstep(0.7, 1.0, m));
}

float roughStepScale(float roughness) {
    return mix(1.6, 0.55, saturate(1.0 - roughness));
}

vec2 refineRayBinarySearch(
    vec3 ro,
    vec3 rd,
    vec2 uvStart,
    float depthStart,
    vec2 uvEnd,
    float depthEnd,
    sampler2D depthTex,
    int refineSteps
) {
    float t0 = 0.0;
    float t1 = 1.0;
    float bestT = 0.0;
    float bestErr = 1e9;

    for (int i = 0; i < refineSteps; i++) {
        float tm = mix(t0, t1, 0.5);
        vec2 uv = mix(uvStart, uvEnd, tm);
        float depth = texture2D(depthTex, uv).r;
        float rayDepth = mix(depthStart, depthEnd, tm);
        float err = depth - rayDepth;

        if (err < 0.0) {
            t1 = tm;
        } else {
            t0 = tm;
        }

        if (abs(err) < bestErr) {
            bestErr = abs(err);
            bestT = tm;
        }
    }

    return mix(uvStart, uvEnd, bestT);
}

vec3 ssrRayMarch(
    vec3 ro,
    vec3 rd,
    float roughness,
    sampler2D depthTex,
    int maxSteps,
    int refineSteps,
    SSROptimizationState opt
) {
    vec2 uv = gl_FragCoord.xy / max(screenSize, vec2(1.0));
    
    // Adaptive ray length based on optimization state
    float rayLen = mix(0.85, 0.25, saturate(roughness)) * opt.adaptiveRayLength;
    float stepScale = roughStepScale(roughness);
    float t = 0.0;
    float hit = 0.0;
    vec2 hitUV = uv;
    float lastDepth = texture2D(depthTex, uv).r;
    vec2 lastUV = uv;
    float thickness = mix(0.0025, 0.0125, saturate(roughness));

    // Adaptive ray count based on roughness
    int adaptiveSteps = int(rendererSSRAdaptiveRays(roughness, opt));
    
    for (int i = 0; i < maxSteps; i++) {
        if (i >= adaptiveSteps) break;
        
        float fi = float(i);
        float hier = mix(1.9, 0.6, saturate(fi / float(maxSteps)));
        float dt = (0.25 + fi / float(maxSteps)) * stepScale * hier * rayLen;
        t += dt;

        vec2 stepUV = rd.xy * dt * 0.5;
        vec2 uv2 = uv + stepUV;

        float inBounds = step(0.0, uv2.x) * step(0.0, uv2.y) * step(uv2.x, 1.0) * step(uv2.y, 1.0);
        if (inBounds < 0.5) break;

        float sceneDepth = (hiZEnabled > 0.5) ? sampleHiZDepth(uv2) : texture2D(depthTex, uv2).r;
        float rayDepth = mix(lastDepth, sceneDepth, saturate(fi / float(maxSteps)));
        float diff = sceneDepth - rayDepth;
        float ndvReject = saturate(abs(dot(normalize(vec3(rd.xy, 0.001)), vec3(0.0, 0.0, 1.0))));

        if (diff < -thickness && ndvReject < 0.999) {
            // Adaptive binary search iterations
            int adaptiveRefine = int(opt.adaptiveSearchIterations);
            vec2 refinedUV = refineRayBinarySearch(ro, rd, lastUV, lastDepth, uv2, sceneDepth, depthTex, adaptiveRefine);
            float ef = edgeFade(refinedUV);
            hitUV = refinedUV;
            hit = ef;
            break;
        }

        lastUV = uv2;
        lastDepth = sceneDepth;
        uv = uv2;

        // Early exit for rough surfaces
        if (roughness > opt.roughnessThreshold && i > maxSteps / 2) break;
    }

    float efOut = edgeFade(hitUV);
    
    // Accumulate statistics
    rendererSSRAccumulateCost(opt, float(adaptiveSteps), t, 0.0);
    
    return vec3(hitUV, hit * efOut);
}

#endif


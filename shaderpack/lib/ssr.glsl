#version 150
#ifndef SSR_GLSL
#define SSR_GLS_GLSL

#include "lib/common.glsl"
#include "lib/ssr_depth.glsl"


// SSR helpers.

float saturate01(float x){ return saturate(x); }

// Edge fade based on proximity to screen borders.
float edgeFade(vec2 uv) {
    vec2 p = abs(uv * 2.0 - 1.0);
    float m = max(p.x, p.y);
    return saturate(1.0 - smoothstep(0.7, 1.0, m));
}

// Roughness-aware step scaling.
float roughStepScale(float roughness) {
    // Lower roughness => smaller steps, higher roughness => larger steps.
    return mix(1.6, 0.55, saturate(1.0 - roughness));
}

// Binary search refine along the last hit segment.
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
    // We use a simple bisection in parametric t.
    float t0 = 0.0;
    float t1 = 1.0;

    float bestT = 0.0;
    float bestErr = 1e9;

    for (int i = 0; i < refineSteps; i++) {
        float tm = mix(t0, t1, 0.5);
        vec3 p = ro + rd * (tm * 1000.0);

        // Project p -> uv
        // Caller must provide depthStart/End mapping via uv. For compatibility we only use sign.
        // Here we approximate by interpolating UV.
        vec2 uv = mix(uvStart, uvEnd, tm);

        float depth = texture2D(depthTex, uv).r;
        // Error metric: if ray depth (proxy) is behind scene depth -> penetration.
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

    vec2 outUV = mix(uvStart, uvEnd, bestT);
    return outUV;
}

// Hierarchical SSR ray march.
// Returns hitUV in xy and hitFactor in z.
vec3 ssrRayMarch(
    vec3 ro,
    vec3 rd,
    float roughness,
    sampler2D depthTex,
    int maxSteps,
    int refineSteps
) {

    // Screen-space origin.
    vec2 uv = gl_FragCoord.xy / max(screenSize, vec2(1.0));

    // Roughness-aware ray length: smoother surfaces travel further.
    float rayLen = mix(0.85, 0.25, saturate(roughness));

    // Step sizing based on roughness.
    float stepScale = roughStepScale(roughness);
    float t = 0.0;

    float hit = 0.0;
    vec2 hitUV = uv;

    float lastDepth = texture2D(depthTex, uv).r;
    vec2 lastUV = uv;

    // Thickness rejection bias. Larger bias for rough surfaces.
    float thickness = mix(0.0025, 0.0125, saturate(roughness));

    // Hierarchical: far steps are larger by increasing t.
    for (int i = 0; i < maxSteps; i++) {
        float fi = float(i);

        float hier = mix(1.9, 0.6, saturate(fi / float(maxSteps)));
        float dt = (0.25 + fi / float(maxSteps)) * stepScale * hier * rayLen;
        t += dt;

        vec2 stepUV = rd.xy * dt * 0.5;
        vec2 uv2 = uv + stepUV;

        float inBounds = step(0.0, uv2.x) * step(0.0, uv2.y) * step(uv2.x, 1.0) * step(uv2.y, 1.0);
        if (inBounds < 0.5) break;

        // Use hierarchical Z depth if enabled, otherwise fall back.
        float sceneDepth = (hiZEnabled > 0.5) ? sampleHiZDepth(uv2) : texture2D(depthTex, uv2).r;


        // Ray depth proxy: conservative interpolation.
        float rayDepth = mix(lastDepth, sceneDepth, saturate(fi / float(maxSteps)));

        // Penetration test with thickness.
        float diff = sceneDepth - rayDepth;

        // Reflection rejection: ignore hits that are too grazing/weak (reduces light leaks).
        float ndvReject = saturate(abs(dot(normalize(vec3(rd.xy, 0.001)), vec3(0.0, 0.0, 1.0))));

        // Reject if the ray is likely behind or too thin.
        if (diff < -thickness && ndvReject < 0.999) {
            // Refinement between last and current.
            vec2 refinedUV = refineRayBinarySearch(
                ro, rd,
                lastUV, lastDepth,
                uv2, sceneDepth,
                depthTex,
                refineSteps
            );

            // Reflection rejection: filter extremely close-to-edge hits.
            float ef = edgeFade(refinedUV);

            hitUV = refinedUV;
            hit = ef;
            break;
        }

        lastUV = uv2;
        lastDepth = sceneDepth;
        uv = uv2;

        // Early roughness: if too rough, stop sooner.
        if (roughness > 0.65 && i > maxSteps / 2) break;
    }

    float efOut = edgeFade(hitUV);
    return vec3(hitUV, hit * efOut);
}


#endif


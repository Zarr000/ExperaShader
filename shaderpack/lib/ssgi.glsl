#version 150

#ifndef SSGI_GLSL
#define SSGI_GLSL

// Screen Space Global Illumination (diffuse) utilities.
// Original implementation designed to work with existing velocity/history buffers.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

// Depth/normal reconstruction helpers.
// Note: production SSGI requires robust normal/roughness buffers. This pack uses
// available normal/roughness where possible and falls back gracefully.

uniform sampler2D gNormalRoughTex;
uniform sampler2D gLinearDepthTex;
uniform sampler2D gHiZ;

// Reconstruct view direction proxy from depth.
vec3 viewDirFromDepth(vec2 uv, float depth) {
    // Approximate: treat depth as linear distance along view.
    // Caller provides NDC->view mapping via project-dependent params in a real pipeline.
    // Here we use a stable approximation: infer view Z from depth and use screen ray from uv.
    vec2 ndc = uv * 2.0 - 1.0;
    vec3 dir = normalize(vec3(ndc, -1.0));
    return dir * (depth + 1e-3);
}

vec3 decodeNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

float getLinearDepth(vec2 uv) {
    return texture2D(gLinearDepthTex, uv).r;
}

// Temporal history reprojection helper using motion vectors.
vec2 reprojectUV(vec2 uv, vec2 motion) {
    // motion is assumed in UV units.
    return uv + motion;
}

// Confidence weighting for GI.
float giConfidence(float depthVar, float normalVar, float roughness) {
    // Depth & normal agreement increases confidence.
    float dC = exp(-depthVar * 8.0);
    float nC = exp(-normalVar * 6.0);
    float rC = mix(1.0, 0.6, saturate(roughness));
    return dC * nC * rC;
}

// Bilateral filter weight.
float bilateralWeight(float centerDepth, float sampleDepth, vec3 centerN, vec3 sampleN, float normalSigma, float depthSigma) {
    float dd = sampleDepth - centerDepth;
    float dn = 1.0 - saturate(dot(centerN, sampleN));
    float w = exp(-(dd * dd) / (2.0 * depthSigma * depthSigma)) * exp(-(dn * dn) / (2.0 * normalSigma * normalSigma));
    return w;
}

#endif


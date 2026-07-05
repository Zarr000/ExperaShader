#version 150

#ifndef SSGI_GLSL
#define SSGI_GLSL

#include "common/math.glsl"
#include "common/uniforms.glsl"

uniform sampler2D gNormalRoughTex;
uniform sampler2D gLinearDepthTex;
uniform sampler2D gHiZ;

vec3 viewDirFromDepth(vec2 uv, float depth) {
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

vec2 reprojectUV(vec2 uv, vec2 motion) {
    return uv + motion;
}

float giConfidence(float depthVar, float normalVar, float roughness) {
    float dC = exp(-depthVar * 8.0);
    float nC = exp(-normalVar * 6.0);
    float rC = mix(1.0, 0.6, saturate(roughness));
    return dC * nC * rC;
}

float bilateralWeight(float centerDepth, float sampleDepth, vec3 centerN, vec3 sampleN, float normalSigma, float depthSigma) {
    float dd = sampleDepth - centerDepth;
    float dn = 1.0 - saturate(dot(centerN, sampleN));
    float w = exp(-(dd * dd) / (2.0 * depthSigma * depthSigma)) * exp(-(dn * dn) / (2.0 * normalSigma * normalSigma));
    return w;
}

#endif


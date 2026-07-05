#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

// Inputs
uniform sampler2D gSSGITemp;          // raw temporal GI
uniform sampler2D gPrevSSGI;         // previous history GI
uniform sampler2D gLinearDepthTex;   // linear depth
uniform sampler2D gNormalRoughTex;   // normal/roughness
uniform sampler2D gMotion;           // motion vectors

// Output
uniform float giTemporal;

vec3 decodeNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

void main() {
    vec3 gi = texture2D(gSSGITemp, vUV).rgb;
    float depthC = texture2D(gLinearDepthTex, vUV).r;
    vec3 N = decodeNormal(texture2D(gNormalRoughTex, vUV).rgb);

    // Reproject history
    vec2 motion = texture2D(gMotion, vUV).xy;
    vec3 prev = texture2D(gPrevSSGI, vUV + motion).rgb;

    // Confidence: depth/normal similarity
    float depthR = texture2D(gLinearDepthTex, vUV + vec2(1.0/max(screenSize.x,1.0),0.0)).r;
    float dVar = abs(depthR - depthC);
    vec3 nR = decodeNormal(texture2D(gNormalRoughTex, vUV + vec2(1.0/max(screenSize.x,1.0),0.0)).rgb);
    float nVar = 1.0 - saturate(dot(N, nR));
    float conf = giConfidence(dVar, nVar, texture2D(gNormalRoughTex, vUV).a);

    // History rejection
    float histErr = length(gi - prev);
    float reject = step(histErr, mix(0.35, 0.12, conf));

    float blend = mix(0.15, 0.6, conf) * reject * clamp(giTemporal, 0.0, 1.0);

    vec3 outGi = mix(prev, gi, blend);
    FragColor = vec4(outGi, 1.0);
}


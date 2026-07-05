#version 150
#ifndef CLOUD_REPROJECTION_GLSL
#define CLOUD_REPROJECTION_GLSL

#include "cloud_common.glsl"
#include "../reprojection.glsl"

// Cloud-specific reprojection utilities
// Handles cloud layer motion and parallax correction

// Compute cloud motion vector for a world position
vec2 cloudMotionVector(vec3 worldPos, vec3 prevWorldPos) {
    vec4 currClip = currentViewProjection * vec4(worldPos, 1.0);
    vec4 prevClip = previousViewProjection * vec4(prevWorldPos, 1.0);

    vec3 currNDC = currClip.xyz / max(currClip.w, 1e-6);
    vec3 prevNDC = prevClip.xyz / max(prevClip.w, 1e-6);

    vec2 currUV = currNDC.xy * 0.5 + 0.5;
    vec2 prevUV = prevNDC.xy * 0.5 + 0.5;

    return currUV - prevUV;
}

// Reproject cloud sample with wind correction
vec2 cloudReprojectWithWind(
    vec2 screenUV,
    float depth,
    vec3 worldPos,
    vec2 windOffset
) {
    // Apply wind to world position for previous frame
    vec3 prevWorldPos = worldPos - vec3(windOffset.x, 0.0, windOffset.y);

    vec2 prevUV = projectUV(
        currentViewProjection,
        previousViewProjection,
        prevWorldPos
    );

    return prevUV;
}

// Check if reprojected cloud sample is valid
bool cloudReprojectionValid(vec2 prevUV, float depth, sampler2D depthTex) {
    if (prevUV.x < 0.0 || prevUV.x > 1.0 ||
        prevUV.y < 0.0 || prevUV.y > 1.0) {
        return false;
    }

    // Depth-based validity check
    float prevDepth = texture2D(depthTex, prevUV).r;
    float depthDiff = abs(prevDepth - depth);

    // Reject if depth difference is too large (occlusion change)
    return depthDiff < 0.1;
}

#endif
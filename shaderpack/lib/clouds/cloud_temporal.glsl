#version 150
#ifndef CLOUD_TEMPORAL_GLSL
#define CLOUD_TEMPORAL_GLSL

#include "cloud_common.glsl"
#include "../common/math.glsl"
#include "../reprojection.glsl"

// Temporal reprojection for cloud accumulation
// Supports history buffer, motion vectors, reprojection,
// history confidence, neighborhood clamping, ghost rejection, adaptive blending

struct CloudTemporalState {
    vec3 historyRadiance;
    float historyConfidence;
    float historyValid;
    vec2 reprojectedUV;
    float blendFactor;
};

// Reproject cloud history to current frame
CloudTemporalState cloudTemporalReproject(
    vec2 screenUV,
    vec3 worldPos,
    float depth,
    sampler2D historyTexture,
    float feedback
) {
    CloudTemporalState state;
    state.historyRadiance = vec3(0.0);
    state.historyConfidence = 0.0;
    state.historyValid = 0.0;
    state.reprojectedUV = screenUV;
    state.blendFactor = feedback;

    // Reproject using motion vectors
    vec2 prevUV = projectUV(
        currentViewProjection,
        previousViewProjection,
        worldPos
    );

    state.reprojectedUV = prevUV;

    // Check if reprojected UV is valid
    if (prevUV.x >= 0.0 && prevUV.x <= 1.0 &&
        prevUV.y >= 0.0 && prevUV.y <= 1.0) {
        state.historyValid = 1.0;

        // Sample history
        state.historyRadiance = texture2D(historyTexture, prevUV).rgb;
        state.historyConfidence = texture2D(historyTexture, prevUV).a;
    }

    return state;
}

// Neighborhood clamping for ghost rejection
vec3 cloudNeighborhoodClamp(vec3 current, vec3 history, vec2 uv, sampler2D depthTex) {
    // Compute neighborhood min/max
    vec3 minColor = current;
    vec3 maxColor = current;

    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 offset = vec2(x, y) * 1.0 / screenSize;
            vec3 neighbor = texture2D(depthTex, uv + offset).rgb;
            minColor = min(minColor, neighbor);
            maxColor = max(maxColor, neighbor);
        }
    }

    // Clamp history to neighborhood
    return clamp(history, minColor, maxColor);
}

// Adaptive blend factor based on confidence and motion
float cloudAdaptiveBlend(
    float baseFeedback,
    float historyConfidence,
    float historyValid,
    float depthChange
) {
    float blend = baseFeedback;

    // Reduce blend when history confidence is low
    blend *= mix(0.5, 1.0, historyConfidence);

    // Reduce blend when history is invalid
    if (historyValid < 0.5) {
        blend = 0.0;
    }

    // Reduce blend on large depth changes (disocclusion)
    float depthWeight = exp(-depthChange * 10.0);
    blend *= mix(0.3, 1.0, depthWeight);

    return clamp(blend, 0.0, 0.95);
}

// Temporal accumulation
vec3 cloudTemporalAccumulate(
    vec3 currentRadiance,
    vec3 historyRadiance,
    float blendFactor
) {
    return mix(currentRadiance, historyRadiance, blendFactor);
}

#endif
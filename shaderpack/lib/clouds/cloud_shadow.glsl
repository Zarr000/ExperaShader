#version 150
#ifndef CLOUD_SHADOW_GLSL
#define CLOUD_SHADOW_GLSL

#include "cloud_common.glsl"
#include "cloud_density.glsl"

// Cloud self-shadowing via light-space raymarching
// Computes attenuation along light path through cloud volume

// Compute self-shadow attenuation at a cloud sample point
float cloudSelfShadow(
    vec3 worldPos,
    vec3 lightDir,
    CloudParameters p,
    CloudRaymarchConfig cfg,
    float time
) {
    float shadow = 1.0;
    float densitySum = 0.0;

    // March towards the light source
    float stepSize = cfg.shadowStepSize;
    float maxDist = 300.0;
    float steps = cfg.shadowSteps;

    float t = 1.0; // Start slightly offset from sample point

    for (float i = 0.0; i < steps; i += 1.0) {
        vec3 samplePos = worldPos + lightDir * t;
        float d = cloudSampleDensityFast(samplePos, p, cfg, time);
        densitySum += d * stepSize;

        // Beer's law extinction
        shadow = exp(-densitySum * CLOUD_EXTINCTION_MAX * 0.03);

        // Early exit if fully shadowed
        if (shadow < 0.01) break;

        t += stepSize * (1.0 + i * 0.1); // Increasing step size for efficiency
    }

    return shadow;
}

// Cloud shadow on terrain (projected from cloud layer)
float cloudTerrainShadow(
    vec3 surfacePos,
    vec3 sunDir,
    CloudParameters p,
    CloudRaymarchConfig cfg,
    float time
) {
    // Trace ray from surface up through cloud layer
    float cloudBase = p.baseHeight;
    float cloudTop = p.topHeight;
    float surfaceY = surfacePos.y;

    // Check if surface is below cloud layer
    if (surfaceY >= cloudTop) return 1.0;

    // Calculate entry and exit points through cloud layer
    float t = 0.0;
    float shadow = 1.0;
    float densitySum = 0.0;

    // Approximate distance through cloud layer along light direction
    float vertDist = cloudTop - max(surfaceY, cloudBase);
    float cosTheta = max(sunDir.y, 0.001);
    float horizDist = vertDist / cosTheta;
    float totalDist = min(horizDist, 500.0);

    if (totalDist <= 0.0) return 1.0;

    float steps = min(cfg.shadowSteps * 0.5, 6.0);
    float stepSize = totalDist / steps;

    for (float i = 0.0; i < steps; i += 1.0) {
        vec3 samplePos = surfacePos + sunDir * (i + 0.5) * stepSize;

        // Check if sample is within cloud layer
        if (samplePos.y >= cloudBase && samplePos.y <= cloudTop) {
            float d = cloudSampleDensityFast(samplePos, p, cfg, time);
            densitySum += d * stepSize;
            shadow = exp(-densitySum * CLOUD_EXTINCTION_MAX * 0.02);
        }

        if (shadow < 0.01) break;
    }

    return shadow;
}

#endif
#version 150
#ifndef CLOUD_RAYMARCH_GLSL
#define CLOUD_RAYMARCH_GLSL

#include "cloud_common.glsl"
#include "cloud_density.glsl"
#include "cloud_lighting.glsl"
#include "cloud_shadow.glsl"
#include "../blue_noise.glsl"

// Optimized volumetric raymarching for clouds
// Supports adaptive step size, early termination, empty-space skipping,
// depth-aware termination, quality scaling, distance-based sampling

struct CloudRaymarchResult {
    vec3 radiance;
    float transmittance;
    float depth;
    float steps;
    float densitySum;
};

// Adaptive step size based on density
float cloudAdaptiveStep(float density, float baseStep, float minStep, float maxStep) {
    float stepScale = 1.0 - density * 0.8;
    return clamp(baseStep * stepScale, minStep, maxStep);
}

// Main cloud raymarch
CloudRaymarchResult cloudRaymarch(
    vec3 rayOrigin,
    vec3 rayDir,
    float rayLength,
    AtmosphereParameters p,
    AtmosphereRuntime r,
    CloudParameters c,
    CloudRaymarchConfig cfg,
    float time,
    vec2 screenUV
) {
    CloudRaymarchResult result;
    result.radiance = vec3(0.0);
    result.transmittance = 1.0;
    result.depth = rayLength;
    result.steps = 0.0;
    result.densitySum = 0.0;

    // Blue noise offset for dithering
    float noiseOffset = blueNoiseInterleaved(screenUV * screenSize, frameTimeCounter);

    // Find cloud intersection
    float cloudBase = c.baseHeight;
    float cloudTop = c.topHeight;

    // Calculate entry and exit distances
    float tMin = -1.0;
    float tMax = -1.0;

    // Simple plane intersection for cloud layer
    if (abs(rayDir.y) > 0.001) {
        float tBase = (cloudBase - rayOrigin.y) / rayDir.y;
        float tTop = (cloudTop - rayOrigin.y) / rayDir.y;

        tMin = min(tBase, tTop);
        tMax = max(tBase, tTop);
    }

    // No cloud intersection
    if (tMax < 0.0 || tMin > rayLength) {
        result.depth = rayLength;
        return result;
    }

    // Clamp to ray length
    tMin = max(tMin, 0.0);
    tMax = min(tMax, rayLength);

    if (tMax <= tMin) {
        result.depth = rayLength;
        return result;
    }

    // March through cloud volume
    float t = tMin + noiseOffset * cfg.stepSize * 0.5;
    float stepSize = cfg.stepSize;
    float maxSteps = cfg.maxSteps;

    // Recenter for empty-space skipping - check if we're inside a cloud
    bool inCloud = false;
    float cloudEntryDist = 0.0;

    for (float i = 0.0; i < maxSteps; i += 1.0) {
        if (t >= tMax || result.transmittance < 0.01) break;

        vec3 samplePos = rayOrigin + rayDir * t;

        // Sample density
        CloudDensitySample sample = cloudSampleDensity(samplePos, c, cfg, time);
        float density = sample.density;

        // Empty-space skipping
        if (density < 0.01) {
            if (!inCloud) {
                // Skip aggressively in empty space
                float skipDist = stepSize * 3.0;
                t += skipDist;
                continue;
            }
        } else {
            if (!inCloud) {
                inCloud = true;
                cloudEntryDist = t;
            }

            // Self-shadowing
            float shadow = 1.0;
            if (density > 0.05) {
                shadow = cloudSelfShadow(samplePos, r.sunDirection, c, cfg, time);
            }

            // Compute lighting
            CloudLighting lig = cloudComputeLighting(p, r, samplePos, -rayDir, density);

            // Silver lining
            float silver = lig.silverLining * (1.0 - shadow);

            // Combine lighting
            vec3 light = lig.sunRadiance * shadow + lig.moonRadiance + lig.ambient + lig.scattered;
            light += vec3(1.0, 0.9, 0.7) * silver * 0.5;

            // Extinction
            float extinction = density * CLOUD_EXTINCTION_MAX * stepSize * 0.1;
            vec3 scatter = density * CLOUD_SCATTERING_MAX * stepSize * 0.1 * light;

            // In-scattering integration
            vec3 contrib = scatter * result.transmittance;
            result.radiance += contrib;
            result.transmittance *= exp(-extinction);
            result.densitySum += density * stepSize;
        }

        // Adaptive step size
        float adaptiveStep = cloudAdaptiveStep(density, stepSize, stepSize * 0.3, stepSize * 2.0);
        t += adaptiveStep;
        result.steps += 1.0;
    }

    // Store cloud depth for compositing
    if (inCloud) {
        result.depth = cloudEntryDist;
    }

    return result;
}

#endif
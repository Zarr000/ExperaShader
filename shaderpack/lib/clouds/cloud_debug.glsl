#version 150
#ifndef CLOUD_DEBUG_GLSL
#define CLOUD_DEBUG_GLSL

#include "cloud_common.glsl"
#include "cloud_density.glsl"
#include "cloud_lighting.glsl"
#include "cloud_raymarch.glsl"

// Cloud debug visualization
// Supports: coverage, density, noise, erosion, raymarch steps,
// lighting, self shadow, cloud shadows, history confidence, reprojection

vec3 cloudDebugVisualization(
    float mode,
    CloudRaymarchResult result,
    CloudDensitySample sample,
    CloudParameters p,
    CloudRaymarchConfig cfg,
    vec3 worldPos,
    float time
) {
    // Mode 0: Normal rendering
    if (mode < 1.0) return result.radiance;

    // Mode 1: Coverage
    if (mode < 2.0) {
        return vec3(sample.coverage);
    }

    // Mode 2: Density
    if (mode < 3.0) {
        return vec3(sample.density);
    }

    // Mode 3: Noise (base shape)
    if (mode < 4.0) {
        vec2 wind = p.windDirection * p.windSpeed * time * 0.5;
        vec3 samplePos = worldPos + vec3(wind.x, 0.0, wind.y);
        float noise = cloudFBM(samplePos * 0.001, cfg.noiseOctaves);
        return vec3(noise);
    }

    // Mode 4: Erosion
    if (mode < 5.0) {
        return vec3(sample.erosion);
    }

    // Mode 5: Raymarch steps
    if (mode < 6.0) {
        float stepNorm = result.steps / cfg.maxSteps;
        return vec3(stepNorm);
    }

    // Mode 6: Lighting (sun contribution)
    if (mode < 7.0) {
        return result.radiance * 2.0;
    }

    // Mode 7: Self shadow
    if (mode < 8.0) {
        float shadow = cloudSelfShadow(worldPos, vec3(0.0, 1.0, 0.0), p, cfg, time);
        return vec3(shadow);
    }

    // Mode 8: Cloud shadows on terrain
    if (mode < 9.0) {
        float terrainShadow = cloudTerrainShadow(worldPos, vec3(0.0, 1.0, 0.0), p, cfg, time);
        return vec3(terrainShadow);
    }

    // Mode 9: Height gradient
    if (mode < 10.0) {
        return vec3(sample.heightGradient);
    }

    // Mode 10: Weather modulation
    if (mode < 11.0) {
        return vec3(sample.weatherModulation);
    }

    return result.radiance;
}

#endif
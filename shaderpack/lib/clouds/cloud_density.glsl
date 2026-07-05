#version 150
#ifndef CLOUD_DENSITY_GLSL
#define CLOUD_DENSITY_GLSL

#include "cloud_common.glsl"
#include "cloud_noise.glsl"
#include "cloud_shape.glsl"
#include "cloud_weather.glsl"

// Physically meaningful cloud density field
// Supports base, middle, high layers with coverage, erosion, humidity, weather

// Sample cloud density at a world position
CloudDensitySample cloudSampleDensity(
    vec3 worldPos,
    CloudParameters p,
    CloudRaymarchConfig cfg,
    float time
) {
    CloudDensitySample s;
    s.density = 0.0;
    s.coverage = 0.0;
    s.erosion = 0.0;
    s.heightGradient = 0.0;
    s.weatherModulation = 0.0;

    float height = worldPos.y;

    // Check if within cloud altitude range
    if (!cloudInRange(height, p.baseHeight, p.topHeight)) {
        return s;
    }

    // Height gradient (0 at base, 1 at top)
    s.heightGradient = cloudHeightGradient(height, p.baseHeight, p.topHeight);

    // Wind offset for animated clouds
    vec2 wind = p.windDirection * p.windSpeed * time * 0.5;
    vec3 windOffset = vec3(wind.x, 0.0, wind.y);

    // Sample position with wind
    vec3 samplePos = worldPos + windOffset;

    // Tiling optimization
    vec3 tilingOffset = cloudTilingOffset(0.0);
    samplePos += tilingOffset;

    // Large-scale coverage noise
    float coverageScale = 0.0005;
    s.coverage = cloudCoverageNoise(samplePos.xz, coverageScale, time);
    s.coverage = saturate(s.coverage * 1.5 - 0.25); // Remap for better distribution
    s.coverage *= p.coverage;

    // Base shape noise (FBM)
    float shapeScale = 0.001;
    float baseShape = cloudFBM(samplePos * shapeScale, cfg.noiseOctaves);

    // Height-based density profile
    float heightProfile = 1.0 - abs(s.heightGradient - 0.5) * 2.0;
    heightProfile = pow(heightProfile, 0.6);

    // Erosion (Worley-based detail)
    float erosionScale = 0.004;
    s.erosion = cloudErosionNoise(samplePos * erosionScale, cfg.noiseOctaves, cfg.detailOctaves);
    s.erosion = 1.0 - s.erosion * p.erosion * 0.5;

    // Weather modulation
    s.weatherModulation = cloudWeatherDensity(p.humidity, p.stormFactor, samplePos, time);

    // Combine into final density
    float rawDensity = baseShape * s.coverage * heightProfile;
    rawDensity *= s.erosion;
    rawDensity *= s.weatherModulation;
    rawDensity *= p.density;

    // Density remapping (threshold for cloud edges)
    float densityThreshold = 0.1;
    s.density = max(rawDensity - densityThreshold, 0.0) / (1.0 - densityThreshold);
    s.density = saturate(s.density);

    return s;
}

// Fast density sample for shadow raymarching (lower quality)
float cloudSampleDensityFast(
    vec3 worldPos,
    CloudParameters p,
    CloudRaymarchConfig cfg,
    float time
) {
    float height = worldPos.y;
    if (!cloudInRange(height, p.baseHeight, p.topHeight)) return 0.0;

    float heightGrad = cloudHeightGradient(height, p.baseHeight, p.topHeight);
    float heightProfile = 1.0 - abs(heightGrad - 0.5) * 2.0;
    heightProfile = pow(heightProfile, 0.6);

    vec2 wind = p.windDirection * p.windSpeed * time * 0.5;
    vec3 samplePos = worldPos + vec3(wind.x, 0.0, wind.y);
    samplePos += cloudTilingOffset(0.0);

    float coverage = cloudCoverageNoise(samplePos.xz, 0.0005, time);
    coverage = saturate(coverage * 1.5 - 0.25) * p.coverage;

    float shape = cloudFBM(samplePos * 0.001, min(cfg.noiseOctaves, 3.0));
    float erosion = 1.0 - cloudErosionNoise(samplePos * 0.004, 2.0, 1.0) * p.erosion * 0.5;

    float density = shape * coverage * heightProfile * erosion * p.density;
    return max(density - 0.15, 0.0) / 0.85;
}

#endif
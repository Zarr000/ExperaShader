#version 150
#ifndef ATMOSPHERE_OPTICAL_DEPTH_GLSL
#define ATMOSPHERE_OPTICAL_DEPTH_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_density.glsl"

// Runtime-driven optical depth computation
// Integrates density along a path through the atmosphere
// Uses camera altitude, weather, and terrain parameters

vec3 atmosphereOpticalDepth(
    float height,
    vec3 scaleHeights,
    float sampleCount,
    AtmosphereRuntime r
) {
    float h = max(height, 0.0);

    // Compute density for each scattering component
    vec3 density = atmosphereCombinedDensity(
        h,
        scaleHeights,
        r.cameraAltitude,
        r.fogAltitude,
        r.waterLevel,
        r.mountainHeight,
        r.weatherIntensity
    );

    // Quality-scaled sample count
    float samples = atmosphereQualityScale(r.quality, 1.0, 2.0, 3.0, 4.0);
    samples = max(samples, sampleCount);

    // Optical depth with altitude-dependent step size
    float stepSize = 0.0015 * (0.8 + 0.2 * saturate(h * 0.001));

    return density * samples * stepSize;
}

// Optical depth along a ray segment
vec3 atmosphereOpticalDepthAlongRay(
    vec3 origin,
    vec3 direction,
    float tMin,
    float tMax,
    vec3 scaleHeights,
    float sampleCount,
    AtmosphereRuntime r
) {
    float samples = atmosphereQualityScale(r.quality, 2.0, 4.0, 6.0, 8.0);
    samples = max(samples, sampleCount);

    float dt = (tMax - tMin) / samples;
    vec3 opticalDepth = vec3(0.0);

    for (float i = 0.0; i < samples; i += 1.0) {
        float t = tMin + (i + 0.5) * dt;
        vec3 pos = origin + direction * t;
        float h = max(length(pos) - ATMOSPHERE_PLANET_RADIUS, 0.0);

        vec3 density = atmosphereCombinedDensity(
            h,
            scaleHeights,
            r.cameraAltitude,
            r.fogAltitude,
            r.waterLevel,
            r.mountainHeight,
            r.weatherIntensity
        );

        opticalDepth += density * dt;
    }

    return opticalDepth;
}

#endif
#version 150
#ifndef WATER_UNDERWATER_GLSL
#define WATER_UNDERWATER_GLSL

#include "water_common.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../weather/weather_fog.glsl"
#include "../weather/weather_lighting.glsl"
#include "../weather/weather_wetness.glsl"

// Underwater rendering
// Fog, color grading, light shafts, surface distortion, exposure adaptation

struct WaterUnderwater {
    vec3 fogColor;
    vec3 lightColor;
    float fogDensity;
    float visibility;
    float distortionStrength;
    float exposureAdaption;
    float causticIntensity;
};

// Compute underwater parameters
WaterUnderwater waterComputeUnderwater(
    vec3 cameraPos, float waterLevel,
    AtmosphereParameters p, AtmosphereRuntime r,
    WeatherFog wf, WeatherLighting wl,
    float causticStrength
) {
    WaterUnderwater u;
    u.fogColor = vec3(0.0);
    u.lightColor = vec3(0.0);
    u.fogDensity = 0.0;
    u.visibility = 1.0;
    u.distortionStrength = 0.0;
    u.exposureAdaption = 0.0;
    u.causticIntensity = 0.0;

    // Depth below water
    float depth = max(waterLevel - cameraPos.y, 0.0);
    depth = min(depth, 50.0);

    // Underwater fog color: absorbs red first, then green, then blue
    vec3 shallowFog = vec3(0.04, 0.2, 0.3);
    vec3 deepFog = vec3(0.005, 0.05, 0.15);
    u.fogColor = mix(shallowFog, deepFog, exp(-depth * 0.1));

    // Light shafts from atmosphere
    u.lightColor = atmosphereAmbientSky(p, r, depth) * 2.0;
    u.lightColor += wl.ambientColor * 0.5;
    u.lightColor += wf.color * 0.2;

    // Fog density from weather and water absorption
    float weatherFog = wf.density * 0.5;
    float absorptionFog = 0.02 * depth;
    u.fogDensity = weatherFog + absorptionFog;
    u.fogDensity = saturate(u.fogDensity);

    // Visibility
    u.visibility = exp(-depth * 0.05) * exp(-u.fogDensity * 2.0);

    // Surface distortion: stronger near surface (bottom of water volume)
    float distFromSurface = abs(cameraPos.y - waterLevel);
    u.distortionStrength = exp(-distFromSurface * 0.5) * 0.3;

    // Exposure adaptation: darker underwater
    u.exposureAdaption = exp(-depth * 0.02);

    // Caustics
    u.causticIntensity = causticStrength * exp(-depth * 0.15);

    return u;
}

#endif
#version 150
#ifndef WATER_UTIL_GLSL
#define WATER_UTIL_GLSL

#include "water_common.glsl"
#include "water_surface.glsl"
#include "water_waves.glsl"
#include "water_normal.glsl"
#include "water_fresnel.glsl"
#include "water_reflection.glsl"
#include "water_refraction.glsl"
#include "water_absorption.glsl"
#include "water_scattering.glsl"
#include "water_caustics.glsl"
#include "water_foam.glsl"
#include "water_shore.glsl"
#include "water_ripple.glsl"
#include "water_weather.glsl"
#include "water_underwater.glsl"
#include "../weather/weather_util.glsl"
#include "../atmosphere/atmosphere_common.glsl"

// Water unified utility
// Single entry point for water rendering with Weather Engine integration

// Complete water surface sample
WaterSurfaceSample waterSampleSurface(
    vec2 pos, vec3 worldPos, float time, float distance,
    WeatherFrame weather, AtmosphereParameters p, AtmosphereRuntime r,
    float quality
) {
    WaterSurfaceSample s;
    s.position = worldPos;
    s.normal = vec3(0.0, 1.0, 0.0);
    s.albedo = vec3(0.0);
    s.roughness = 0.02;
    s.foam = 0.0;
    s.depth = 0.0;
    s.fresnel = 0.0;

    // Compute weather-driven parameters
    WaterParameters waterParams = weatherDrivenWater(
        weather.state, weather.wind, weather.precipitation, weather.wetness, quality
    );

    // Compute normal
    s.normal = waterComputeNormal(pos, time, weather.wind, quality, distance);

    // Compute depth (use world Y as approximation)
    s.depth = max(0.0, worldPos.y - 62.0);

    // Base albedo with absorption
    s.albedo = waterSurfaceAlbedo(
        s.depth, waterParams.shallowColor, waterParams.deepColor, waterParams.absorptionCoeff
    );

    // Foam
    s.foam = waterComputeFoam(
        1.0 - saturate(dot(s.normal, vec3(0.0, 1.0, 0.0))),
        5.0, // shoreDist placeholder
        weather.wind.speed, weather.precipitation, weather.wind,
        waterParams.shoreWidth
    );

    // Fresnel
    s.fresnel = waterFresnelRough(0.5, waterParams.roughness);

    return s;
}

// Water surface BRDF
vec3 waterSurfaceBRDF(
    vec3 L, vec3 V, vec3 N, vec3 albedo, float roughness,
    vec3 reflection, vec3 scattering, float fresnel
) {
    vec3 spec = waterSpecularBRDF(L, V, N, roughness);
    vec3 diff = waterDiffuseBRDF(albedo, saturate(dot(N, L)));

    // Combine reflection with specular
    vec3 finalSpec = mix(spec, reflection, fresnel);

    // Add scattering
    vec3 finalDiff = diff + scattering * 0.3;

    return finalSpec + finalDiff;
}

#endif
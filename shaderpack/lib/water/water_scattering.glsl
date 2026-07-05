#version 150
#ifndef WATER_SCATTERING_GLSL
#define WATER_SCATTERING_GLSL

#include "water_common.glsl"
#include "water_absorption.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../weather/weather_fog.glsl"

// Water scattering model
// Single scattering, forward scattering, ambient underwater lighting

struct WaterScattering {
    vec3 singleScatter;
    vec3 ambient;
    vec3 transmittance;
    float scatterStrength;
};

// Compute water scattering
WaterScattering waterComputeScattering(
    vec3 L, vec3 V, vec3 N,
    vec3 albedo, float depth,
    AtmosphereParameters p, AtmosphereRuntime r,
    WeatherFog wf
) {
    WaterScattering s;
    s.singleScatter = vec3(0.0);
    s.ambient = vec3(0.0);
    s.transmittance = vec3(1.0);
    s.scatterStrength = 0.0;

    // Light direction
    float NoL = saturate(dot(N, L));

    // Beer-Lambert transmittance through water
    s.transmittance = waterBeerLambert(p.rayleighScattering * 2.0, depth);

    // Subsurface scattering approximation
    float scatterDist = 1.0 / (WATER_SCATTERING_COEFF.r + 0.001);
    vec3 scatter = waterBeerLambert(WATER_SCATTERING_COEFF, scatterDist);

    // Single scattering contribution
    s.singleScatter = albedo * scatter * NoL;

    // Ambient underwater lighting from atmosphere + weather fog
    vec3 skyAmbient = atmosphereAmbientSky(p, r, depth);
    vec3 weatherAmbient = wf.color * 0.1;
    s.ambient = (skyAmbient + weatherAmbient) * 0.3;

    // Forward scattering lobe
    float forwardPhase = 0.5 + 0.5 * saturate(dot(V, L));
    s.singleScatter *= forwardPhase;

    s.scatterStrength = length(s.singleScatter);

    return s;
}

#endif
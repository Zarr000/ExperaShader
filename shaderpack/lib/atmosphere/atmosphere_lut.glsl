#version 150
#ifndef ATMOSPHERE_LUT_GLSL
#define ATMOSPHERE_LUT_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_transmittance.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_multiscatter.glsl"
#include "atmosphere_sun.glsl"
#include "atmosphere_moon.glsl"

// Complete Sky LUT implementation
// Supports:
// - Runtime updates based on current atmosphere state
// - Shared usage across sky, clouds, fog, and water rendering
// - Quality scaling for LUT resolution and sample count
// - Avoids duplicated LUT evaluation

// Transmittance LUT - precomputed transmittance for reuse
vec3 atmosphereTransmittanceLUT(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    float height
) {
    vec3 scaleHeights = vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight);
    float samples = atmosphereQualityScale(r.quality, 1.0, 2.0, 3.0, 4.0);
    return atmosphereTransmittance(height, scaleHeights, samples, r);
}

// Sky LUT - precomputed sky radiance for reuse across systems
vec3 atmosphereSkyLUT(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosThetaSun = clamp(dot(viewDir, r.sunDirection), -1.0, 1.0);
    float cosThetaMoon = clamp(dot(viewDir, r.moonDirection), -1.0, 1.0);

    // Transmittance
    vec3 trans = atmosphereTransmittanceLUT(p, r, height);

    // Single scattering
    vec3 rayleighScatter = atmosphereRayleighScatter(p, cosThetaSun);
    vec3 mieScatter = atmosphereMieScatter(p, cosThetaSun);

    // Moon scattering (weaker)
    vec3 moonScatter = atmosphereRayleighScatter(p, cosThetaMoon) * 0.06;
    vec3 moonMie = atmosphereMieScatter(p, cosThetaMoon) * 0.03;

    // Multiple scattering
    vec3 multiScatter = atmosphereMultiScatter(p, r, cosThetaSun, height);

    // Sun and moon illumination
    vec3 sunIllum = atmosphereSunIllumination(p, r, viewDir, height);
    vec3 moonIllum = atmosphereMoonIllumination(p, r, viewDir, height);

    // Horizon glow
    float elevation = r.sunElevation;
    vec3 horizonColor = atmosphereHorizonColor(elevation, r.weatherIntensity);
    float horizonWeight = exp(-abs(viewDir.y) * 5.0);
    vec3 horizonGlow = horizonColor * horizonWeight * 0.1;

    // Combine all contributions
    vec3 skyRadiance = (rayleighScatter + mieScatter + moonScatter + moonMie) * trans;
    skyRadiance += multiScatter * trans;
    skyRadiance += sunIllum + moonIllum;
    skyRadiance += horizonGlow;

    // Quality scaling
    float lutQuality = atmosphereQualityScale(r.quality, 0.6, 0.8, 0.95, 1.0);
    skyRadiance *= lutQuality;

    return skyRadiance;
}

// Shared LUT evaluation for fog/clouds/water
// Returns pre-integrated scattering for a given view direction
vec3 atmosphereSharedScattering(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height,
    float distance
) {
    // Use LUT as base
    vec3 lut = atmosphereSkyLUT(p, r, viewDir, height);

    // Distance-based attenuation
    float attenuation = exp(-distance * r.fogDensity * 0.01);

    // Height-based adjustment
    float heightFactor = exp(-height * 0.0005);

    return lut * attenuation * heightFactor;
}

#endif
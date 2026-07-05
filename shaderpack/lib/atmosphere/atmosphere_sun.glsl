#version 150
#ifndef ATMOSPHERE_SUN_GLSL
#define ATMOSPHERE_SUN_GLSL

#include "atmosphere_common.glsl"

// Production solar radiance model
// Computes physically-based sun color and intensity based on:
// - Real sun direction and elevation
// - Atmospheric attenuation (Rayleigh + Mie extinction along view path)
// - Horizon coloration (golden hour, twilight phases)
// - Solar radiance with angular diameter

vec3 atmosphereSunRadiance(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosTheta = clamp(dot(r.sunDirection, viewDir), -1.0, 1.0);
    float elevation = r.sunElevation;

    // Solar disc with angular diameter (~0.53 degrees)
    float sunAngularRadius = 0.00465; // ~0.266 degrees in radians
    float disc = smoothstep(
        cos(sunAngularRadius * 1.5),
        cos(sunAngularRadius * 0.5),
        cosTheta
    );

    // Atmospheric extinction along view path
    float viewZenith = abs(viewDir.y);
    float airmass = 1.0 / max(viewZenith, 0.01);
    float extinction = exp(-height * 0.0005 * airmass);

    // Elevation-based intensity with smooth transitions
    float dayIntensity = smoothstep(-0.05, 0.2, elevation);
    float twilightIntensity = atmosphereTwilightFactor(elevation);

    // Solar radiance color temperature shift
    // Sun at zenith: ~5778K (white)
    // Sun at horizon: ~2000K (deep red/orange)
    vec3 zenithColor = vec3(1.0, 0.98, 0.92); // Slightly warm white
    vec3 horizonColor = vec3(1.0, 0.4, 0.1);  // Deep orange/red
    vec3 twilightColor = vec3(0.8, 0.2, 0.05); // Deep red during twilight

    // Color blending based on elevation
    float horizonBlend = exp(-abs(elevation) * 12.0);
    float twilightBlend = exp(-abs(elevation + 0.05) * 8.0) * (1.0 - smoothstep(-0.05, 0.1, elevation));

    vec3 sunColor = zenithColor;
    sunColor = mix(sunColor, horizonColor, horizonBlend);
    sunColor = mix(sunColor, twilightColor, twilightBlend);

    // Golden hour enhancement
    float goldenHour = atmosphereGoldenHourFactor(elevation);
    vec3 goldenColor = vec3(1.0, 0.7, 0.3);
    sunColor = mix(sunColor, goldenColor, goldenHour * 0.6);

    // Atmospheric attenuation
    float attenuation = atmosphereAttenuation(height, 0.8 + r.weatherIntensity * 0.4);

    // Solar radiance intensity
    float intensity = disc * dayIntensity * attenuation;
    intensity *= (0.5 + 0.5 * smoothstep(-0.2, 0.35, elevation));
    intensity *= (0.7 + 0.3 * twilightIntensity);

    // Weather dimming
    intensity *= (1.0 - r.weatherIntensity * 0.4);

    // Apply sun intensity parameter
    intensity *= p.sunIntensity;

    // Glow around the sun (aureole)
    float glow = exp(-(1.0 - cosTheta) * 200.0) * 0.15 * dayIntensity;
    glow *= (1.0 - r.weatherIntensity * 0.5);

    return sunColor * (intensity + glow);
}

// Sun sky illumination (scattered light from sun direction)
vec3 atmosphereSunIllumination(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosTheta = clamp(dot(r.sunDirection, viewDir), -1.0, 1.0);
    float elevation = r.sunElevation;

    // Scattered sunlight for sky illumination
    float dayFactor = smoothstep(-0.1, 0.15, elevation);
    float twilightFactor = atmosphereTwilightFactor(elevation);

    // Rayleigh scattering angular dependence
    float rayleighPhase = 0.75 * (1.0 + cosTheta * cosTheta);

    // Mie scattering forward peak
    float miePhase = atmosphereMiePhase(p.mieG, cosTheta);

    // Blend between day and twilight colors
    vec3 dayColor = vec3(1.0, 0.95, 0.9);
    vec3 twilightColor = vec3(1.0, 0.5, 0.2);
    vec3 color = mix(twilightColor, dayColor, dayFactor);

    float intensity = (rayleighPhase * 0.7 + miePhase * 0.3) * dayFactor;
    intensity *= (0.6 + 0.4 * twilightFactor);
    intensity *= atmosphereAttenuation(height, 0.3);
    intensity *= (1.0 - r.weatherIntensity * 0.3);

    return color * intensity * p.sunIntensity;
}

#endif
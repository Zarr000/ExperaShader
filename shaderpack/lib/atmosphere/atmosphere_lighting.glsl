#version 150
#ifndef ATMOSPHERE_LIGHTING_GLSL
#define ATMOSPHERE_LIGHTING_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_transmittance.glsl"
#include "atmosphere_sun.glsl"
#include "atmosphere_moon.glsl"
#include "atmosphere_multiscatter.glsl"

// Runtime-driven atmosphere lighting
// Integrates sun, moon, scattering, and ambient into a unified lighting model

vec3 atmosphereSunLighting(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosTheta = clamp(dot(r.sunDirection, viewDir), -1.0, 1.0);
    float elevation = r.sunElevation;

    // Sun radiance (direct solar disc)
    vec3 sunRad = atmosphereSunRadiance(p, r, viewDir, height);

    // Scattered sunlight
    vec3 rayleigh = atmosphereRayleighScatter(p, cosTheta);
    vec3 mie = atmosphereMieScatter(p, cosTheta);

    // Transmittance
    vec3 scaleHeights = vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight);
    float samples = atmosphereQualityScale(r.quality, 1.0, 2.0, 3.0, 4.0);
    vec3 trans = atmosphereTransmittance(height, scaleHeights, samples, r);

    // Multiple scattering
    vec3 multi = atmosphereMultiScatter(p, r, cosTheta, height);

    // Horizon coloration
    vec3 horizon = atmosphereHorizonColor(elevation, r.weatherIntensity);
    float horizonWeight = exp(-abs(viewDir.y) * 5.0);

    // Day/night transition
    float dayFactor = smoothstep(-0.1, 0.2, elevation);
    float twilightFactor = atmosphereTwilightFactor(elevation);

    // Combine
    vec3 lighting = (rayleigh + mie) * trans * p.sunIntensity;
    lighting += multi * trans;
    lighting += sunRad;
    lighting += horizon * horizonWeight * 0.05 * dayFactor;

    // Weather influence
    lighting *= (1.0 - r.weatherIntensity * 0.3);

    return lighting;
}

vec3 atmosphereMoonLighting(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosTheta = clamp(dot(r.moonDirection, viewDir), -1.0, 1.0);
    float elevation = r.moonElevation;

    // Moon radiance (direct lunar disc)
    vec3 moonRad = atmosphereMoonRadiance(p, r, viewDir, height);

    // Scattered moonlight
    vec3 rayleigh = atmosphereRayleighScatter(p, cosTheta) * 0.12;
    vec3 mie = atmosphereMieScatter(p, cosTheta) * 0.07;

    // Transmittance
    vec3 scaleHeights = vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight);
    float samples = atmosphereQualityScale(r.quality, 1.0, 2.0, 3.0, 4.0);
    vec3 trans = atmosphereTransmittance(height, scaleHeights, samples, r);

    // Phase-based brightness
    float phaseBrightness = r.moonIllumination;

    // Night visibility
    float nightFactor = 1.0 - smoothstep(-0.1, 0.05, r.sunElevation);
    float moonVisibility = smoothstep(-0.2, 0.05, elevation);

    // Combine
    vec3 lighting = (rayleigh + mie) * trans * p.moonIntensity * phaseBrightness;
    lighting += moonRad;
    lighting *= nightFactor * moonVisibility;

    return lighting;
}

// Unified atmosphere lighting for deferred pass
vec3 atmosphereDeferredLighting(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 worldPos,
    vec3 normal,
    vec3 viewDir,
    float roughness
) {
    float height = max(worldPos.y - 64.0, 0.0);

    // Sun lighting
    float NoL_sun = saturate(dot(normal, r.sunDirection));
    vec3 sunLight = atmosphereSunLighting(p, r, viewDir, height) * NoL_sun;

    // Moon lighting
    float NoL_moon = saturate(dot(normal, r.moonDirection));
    vec3 moonLight = atmosphereMoonLighting(p, r, viewDir, height) * NoL_moon;

    // Ambient sky
    vec3 ambient = atmosphereAmbientSky(p, r, height);
    float hemiWeight = saturate(normal.y * 0.5 + 0.5);
    ambient *= hemiWeight;

    // Roughness-based specular reduction
    float specFactor = 1.0 - roughness * 0.5;
    sunLight *= specFactor;
    moonLight *= specFactor;

    return sunLight + moonLight + ambient;
}

#endif
#version 150
#ifndef ATMOSPHERE_MULTISCATTER_GLSL
#define ATMOSPHERE_MULTISCATTER_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_transmittance.glsl"

// Upgraded multiple scattering approximation
// Computes secondary scattering, ambient sky lighting,
// ground contribution, and energy conservation

vec3 atmosphereMultiScatter(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    float cosTheta,
    float height
) {
    float elevation = r.sunElevation;
    float quality = r.quality;
    float weather = r.weatherIntensity;

    // Quality-scaled multi-scattering
    float msQuality = atmosphereQualityScale(quality, 0.3, 0.6, 0.8, 1.0);

    // Compute secondary scattering contribution
    // First order: single scattering
    vec3 rayleigh = p.rayleighScattering;
    vec3 mie = p.mieScattering;
    vec3 totalScatter = rayleigh + mie;

    // Second order: scattered light scatters again
    // Approximation using spherical harmonic-like distribution
    float isotropy = 0.5 + 0.5 * abs(cosTheta); // More isotropic at low angles
    vec3 secondary = totalScatter * totalScatter * 0.5 * isotropy;

    // Ambient sky lighting (hemispherical)
    float horizonWeight = saturate(1.0 - abs(elevation) * 0.5);
    float dayWeight = smoothstep(-0.1, 0.15, elevation);
    vec3 ambientSky = totalScatter * (0.15 + 0.25 * dayWeight);
    ambientSky *= (0.6 + 0.4 * horizonWeight);

    // Ground contribution (albedo approximation)
    // Typical ground albedo: grass ~0.15, snow ~0.8, water ~0.06
    float groundAlbedo = 0.18; // Average ground
    float groundVisibility = 1.0 - saturate(abs(elevation));
    vec3 groundContribution = totalScatter * groundAlbedo * groundVisibility * 0.3;

    // Energy conservation: ensure total scattering doesn't exceed 1
    vec3 totalMS = (secondary + ambientSky + groundContribution) * msQuality;
    totalMS = min(totalMS, vec3(1.0));

    // Weather influence (increases multi-scattering in fog/rain)
    float weatherBoost = 1.0 + weather * 0.3;
    totalMS *= weatherBoost;

    // Altitude-based reduction
    float altitudeFactor = exp(-height * 0.0001);
    totalMS *= (0.8 + 0.2 * altitudeFactor);

    return totalMS;
}

// Ambient sky light for diffuse lighting
vec3 atmosphereAmbientSky(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    float height
) {
    float elevation = r.sunElevation;
    float quality = r.quality;

    // Day/night blend
    float dayFactor = smoothstep(-0.1, 0.2, elevation);
    float nightFactor = 1.0 - dayFactor;

    // Sky color during day (blue)
    vec3 daySky = p.rayleighScattering * 0.8 + p.mieScattering * 0.2;
    daySky *= vec3(0.4, 0.6, 1.0); // Blue tint

    // Sky color during twilight
    vec3 twilightSky = vec3(0.6, 0.3, 0.1);

    // Sky color at night (dark blue)
    vec3 nightSky = vec3(0.02, 0.03, 0.08);

    // Blend based on time of day
    vec3 skyColor = mix(nightSky, twilightSky, smoothstep(-0.2, -0.05, elevation));
    skyColor = mix(skyColor, daySky, smoothstep(-0.05, 0.15, elevation));

    // Altitude darkening
    float altitudeFactor = exp(-height * 0.0002);
    skyColor *= (0.7 + 0.3 * altitudeFactor);

    // Moonlight contribution to ambient
    float moonFactor = smoothstep(-0.15, 0.05, r.moonElevation) * r.moonIllumination;
    vec3 moonAmbient = vec3(0.05, 0.07, 0.15) * moonFactor * nightFactor;
    skyColor += moonAmbient;

    // Quality scaling
    float ambientQuality = atmosphereQualityScale(quality, 0.5, 0.7, 0.9, 1.0);
    skyColor *= ambientQuality;

    return skyColor;
}

#endif
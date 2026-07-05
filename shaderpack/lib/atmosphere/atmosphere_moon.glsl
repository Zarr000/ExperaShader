#version 150
#ifndef ATMOSPHERE_MOON_GLSL
#define ATMOSPHERE_MOON_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_mie.glsl"

// Production moon rendering model
// Supports:
// - Runtime moon direction and elevation
// - Moon phase (new moon to full moon)
// - Moon illumination based on phase
// - Atmospheric attenuation
// - Night brightness adaptation

vec3 atmosphereMoonRadiance(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosTheta = clamp(dot(r.moonDirection, viewDir), -1.0, 1.0);
    float elevation = r.moonElevation;

    // Moon angular diameter (~0.5 degrees, similar to sun)
    float moonAngularRadius = 0.00435;
    float disc = smoothstep(
        cos(moonAngularRadius * 1.5),
        cos(moonAngularRadius * 0.5),
        cosTheta
    );

    // Moon phase illumination
    // phase=0: new moon, phase=1: full moon
    float phase = r.moonPhase;
    float illumination = r.moonIllumination;

    // Phase-based brightness (full moon is ~400x dimmer than sun)
    float phaseBrightness = mix(0.02, 1.0, illumination);

    // Atmospheric extinction
    float viewZenith = abs(viewDir.y);
    float airmass = 1.0 / max(viewZenith, 0.01);
    float extinction = exp(-height * 0.0008 * airmass);

    // Elevation-based visibility
    float elevationFactor = smoothstep(-0.2, 0.05, elevation);

    // Moon color: slightly blue-tinted white
    vec3 moonColor = vec3(0.75, 0.8, 0.95);

    // Atmospheric reddening near horizon
    float horizonReddening = exp(-abs(elevation) * 10.0);
    vec3 horizonColor = vec3(0.9, 0.6, 0.4);
    moonColor = mix(moonColor, horizonColor, horizonReddening * 0.3);

    // Intensity calculation
    float intensity = disc * phaseBrightness * elevationFactor;
    intensity *= extinction;
    intensity *= p.moonIntensity;

    // Weather dimming (less than sun - moonlight penetrates clouds better)
    intensity *= (1.0 - r.weatherIntensity * 0.2);

    // Moon glow (aureole) - softer than sun
    float glow = exp(-(1.0 - cosTheta) * 100.0) * 0.08 * elevationFactor;
    glow *= illumination;

    return moonColor * (intensity + glow);
}

// Moon sky illumination (scattered moonlight)
vec3 atmosphereMoonIllumination(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosTheta = clamp(dot(r.moonDirection, viewDir), -1.0, 1.0);
    float elevation = r.moonElevation;

    // Moonlight is scattered Rayleigh (blue) at night
    float nightFactor = 1.0 - smoothstep(-0.1, 0.05, r.sunElevation);
    float moonVisibility = smoothstep(-0.2, 0.05, elevation);

    // Rayleigh scattering of moonlight
    float rayleighPhase = 0.75 * (1.0 + cosTheta * cosTheta);

    // Mie scattering (weaker for moon)
    float miePhase = atmosphereMiePhase(p.mieG, cosTheta) * 0.3;

    // Moonlight color: blue-tinted
    vec3 moonLightColor = vec3(0.1, 0.15, 0.3);

    float intensity = (rayleighPhase * 0.5 + miePhase * 0.2) * nightFactor * moonVisibility;
    intensity *= r.moonIllumination;
    intensity *= atmosphereAttenuation(height, 0.2);
    intensity *= p.moonIntensity;

    return moonLightColor * intensity;
}

// Night sky ambient from moon
vec3 atmosphereMoonAmbient(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    float height
) {
    float nightFactor = 1.0 - smoothstep(-0.1, 0.05, r.sunElevation);
    float moonVisibility = smoothstep(-0.2, 0.05, r.moonElevation);

    // Ambient moonlight (hemispherical approximation)
    vec3 ambientColor = vec3(0.02, 0.03, 0.06);
    float intensity = nightFactor * moonVisibility * r.moonIllumination * 0.5;
    intensity *= atmosphereAttenuation(height, 0.1);
    intensity *= p.moonIntensity;

    return ambientColor * intensity;
}

#endif
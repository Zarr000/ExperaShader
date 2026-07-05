#version 150
#ifndef ATMOSPHERE_SKY_GLSL
#define ATMOSPHERE_SKY_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_ozone.glsl"
#include "atmosphere_transmittance.glsl"
#include "atmosphere_multiscatter.glsl"
#include "atmosphere_lighting.glsl"
#include "atmosphere_lut.glsl"
#include "atmosphere_sun.glsl"
#include "atmosphere_moon.glsl"
#include "atmosphere_stars.glsl"

// Production sky color computation
// Integrates all atmosphere components into final sky radiance

vec3 atmosphereSkyColor(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosThetaSun = clamp(dot(viewDir, r.sunDirection), -1.0, 1.0);
    float cosThetaMoon = clamp(dot(viewDir, r.moonDirection), -1.0, 1.0);
    float sunElevation = r.sunElevation;
    float moonElevation = r.moonElevation;

    // Single scattering
    vec3 rayleighScatter = atmosphereRayleighScatter(p, cosThetaSun);
    vec3 mieScatter = atmosphereMieScatter(p, cosThetaSun);

    // Ozone absorption
    vec3 ozone = atmosphereOzoneAbsorption(height, p.ozoneAbsorption, p.ozoneScaleHeight);

    // Transmittance (reuse LUT)
    vec3 trans = atmosphereTransmittanceLUT(p, r, height);

    // Multiple scattering
    vec3 multi = atmosphereMultiScatter(p, r, cosThetaSun, height);

    // Sun and moon lighting
    vec3 sunLight = atmosphereSunLighting(p, r, viewDir, height);
    vec3 moonLight = atmosphereMoonLighting(p, r, viewDir, height);

    // Sky LUT (pre-integrated)
    vec3 lut = atmosphereSkyLUT(p, r, viewDir, height);

    // Stars
    vec3 stars = atmosphereStars(sunElevation, moonElevation, r.quality);

    // Horizon glow
    vec3 horizonColor = atmosphereHorizonColor(sunElevation, r.weatherIntensity);
    float horizonWeight = exp(-abs(viewDir.y) * 5.0);
    vec3 horizonGlow = horizonColor * horizonWeight * 0.08;

    // Twilight glow
    float twilightFactor = atmosphereTwilightFactor(sunElevation);
    vec3 twilightColor = vec3(0.8, 0.3, 0.1) * twilightFactor * 0.05;
    twilightColor *= exp(-abs(viewDir.y) * 3.0);

    // Moon ambient
    vec3 moonAmbient = atmosphereMoonAmbient(p, r, height);

    // Combine all contributions
    vec3 skyColor = (rayleighScatter + mieScatter + ozone) * trans;
    skyColor += multi * trans;
    skyColor += sunLight + moonLight;
    skyColor += lut * 0.5; // LUT as additional scattering contribution
    skyColor += stars;
    skyColor += horizonGlow;
    skyColor += twilightColor;
    skyColor += moonAmbient;

    // Night brightness adaptation
    float nightAdapt = atmosphereNightAdaptation(sunElevation, moonElevation, r.moonIllumination);
    skyColor *= nightAdapt;

    // Weather influence
    skyColor *= (1.0 - r.weatherIntensity * 0.2);

    return skyColor;
}

#endif
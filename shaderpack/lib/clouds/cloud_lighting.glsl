#version 150
#ifndef CLOUD_LIGHTING_GLSL
#define CLOUD_LIGHTING_GLSL

#include "cloud_common.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../atmosphere/atmosphere_mie.glsl"
#include "../atmosphere/atmosphere_rayleigh.glsl"
#include "../atmosphere/atmosphere_lut.glsl"

// Cloud lighting model
// Integrates with Atmosphere Engine V2 for physically-based sun/moon/scattering
// Supports silver lining, energy conservation, ambient sky

struct CloudLighting {
    vec3 sunRadiance;
    vec3 moonRadiance;
    vec3 ambient;
    vec3 scattered;
    float phaseSun;
    float phaseMoon;
    float silverLining;
};

// Henyey-Greenstein phase function for clouds
float cloudPhase(float cosTheta, float g) {
    float gg = g * g;
    float denom = 1.0 + gg - 2.0 * g * cosTheta;
    return (1.0 - gg) / (4.0 * ATMOSPHERE_PI * sqrt(denom * denom * denom));
}

// Dual-lobe phase function (forward + backward for silver lining)
float cloudPhaseDual(float cosTheta, float g1, float g2, float blend) {
    float phase1 = cloudPhase(cosTheta, g1);
    float phase2 = cloudPhase(cosTheta, g2);
    return mix(phase1, phase2, blend);
}

// Compute cloud lighting at a sample point
CloudLighting cloudComputeLighting(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 worldPos,
    vec3 viewDir,
    float density
) {
    CloudLighting lig;
    lig.sunRadiance = vec3(0.0);
    lig.moonRadiance = vec3(0.0);
    lig.ambient = vec3(0.0);
    lig.scattered = vec3(0.0);
    lig.phaseSun = 0.0;
    lig.phaseMoon = 0.0;
    lig.silverLining = 0.0;

    float cosThetaSun = clamp(dot(viewDir, r.sunDirection), -1.0, 1.0);
    float cosThetaMoon = clamp(dot(viewDir, r.moonDirection), -1.0, 1.0);
    float height = max(worldPos.y - 64.0, 0.0);

    // Phase function for clouds
    lig.phaseSun = cloudPhaseDual(cosThetaSun, CLOUD_PHASE_G, CLOUD_PHASE_G_SILVER, 0.15);
    lig.phaseMoon = cloudPhase(cosThetaMoon, CLOUD_PHASE_G);

    // Silver lining effect (backscatter when looking towards sun through thin clouds)
    float silverCos = dot(-viewDir, r.sunDirection);
    lig.silverLining = cloudPhase(silverCos, CLOUD_PHASE_G_SILVER) * 0.3;
    lig.silverLining *= (1.0 - density) * 0.5; // Stronger at cloud edges

    // Sun radiance from atmosphere
    vec3 sunRad = atmosphereSunRadiance(p, r, viewDir, height);
    vec3 sunIllum = atmosphereSunIllumination(p, r, viewDir, height);

    // Moon radiance from atmosphere
    vec3 moonRad = atmosphereMoonRadiance(p, r, viewDir, height);
    vec3 moonIllum = atmosphereMoonIllumination(p, r, viewDir, height);

    // Combine direct and scattered light
    lig.sunRadiance = (sunRad + sunIllum * 0.3) * lig.phaseSun;
    lig.moonRadiance = (moonRad + moonIllum * 0.3) * lig.phaseMoon;

    // Ambient sky from atmosphere
    lig.ambient = atmosphereAmbientSky(p, r, height);

    // Multiple scattering approximation for clouds
    // Clouds are highly scattering, so multiple scattering dominates
    float msFactor = density * 0.5;
    vec3 msColor = p.rayleighScattering * 2.0 + p.mieScattering * 4.0;
    lig.scattered = msColor * msFactor * 2.0;

    // Energy conservation: limit total scattering
    float totalEnergy = length(lig.sunRadiance + lig.moonRadiance + lig.ambient + lig.scattered);
    if (totalEnergy > 1.0) {
        float inv = 1.0 / totalEnergy;
        lig.sunRadiance *= inv;
        lig.moonRadiance *= inv;
        lig.ambient *= inv;
        lig.scattered *= inv;
    }

    return lig;
}

#endif
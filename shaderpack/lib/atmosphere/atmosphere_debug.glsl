#version 150
#ifndef ATMOSPHERE_DEBUG_GLSL
#define ATMOSPHERE_DEBUG_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_ozone.glsl"
#include "atmosphere_transmittance.glsl"
#include "atmosphere_optical_depth.glsl"
#include "atmosphere_multiscatter.glsl"
#include "atmosphere_sun.glsl"
#include "atmosphere_moon.glsl"
#include "atmosphere_lut.glsl"
#include "atmosphere_density.glsl"

// Expanded atmosphere debug visualization
// Supports:
// 0: Normal rendering
// 1: Rayleigh scattering
// 2: Mie scattering
// 3: Ozone absorption
// 4: Transmittance
// 5: Optical depth
// 6: Multiple scattering
// 7: Sun radiance
// 8: Moon radiance
// 9: Sky LUT
// 10: Density
// 11: Altitude
// 12: Combined scattering components

vec3 atmosphereDebugColor(
    float mode,
    AtmosphereParameters p,
    AtmosphereRuntime r,
    vec3 viewDir,
    float height
) {
    float cosThetaSun = clamp(dot(viewDir, r.sunDirection), -1.0, 1.0);
    float cosThetaMoon = clamp(dot(viewDir, r.moonDirection), -1.0, 1.0);

    if (mode < 1.0) return vec3(0.0); // Normal rendering

    // Mode 1: Rayleigh scattering
    if (mode < 2.0) {
        vec3 rayleigh = atmosphereRayleighScatter(p, cosThetaSun);
        return rayleigh * 10.0; // Amplify for visibility
    }

    // Mode 2: Mie scattering
    if (mode < 3.0) {
        vec3 mie = atmosphereMieScatter(p, cosThetaSun);
        return mie * 20.0;
    }

    // Mode 3: Ozone absorption
    if (mode < 4.0) {
        vec3 ozone = atmosphereOzoneAbsorption(height, p.ozoneAbsorption, p.ozoneScaleHeight);
        return ozone * 5.0;
    }

    // Mode 4: Transmittance
    if (mode < 5.0) {
        vec3 trans = atmosphereTransmittanceLUT(p, r, height);
        return trans;
    }

    // Mode 5: Optical depth
    if (mode < 6.0) {
        vec3 scaleHeights = vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight);
        vec3 od = atmosphereOpticalDepth(height, scaleHeights, 2.0, r);
        return od * 50.0;
    }

    // Mode 6: Multiple scattering
    if (mode < 7.0) {
        vec3 ms = atmosphereMultiScatter(p, r, cosThetaSun, height);
        return ms * 5.0;
    }

    // Mode 7: Sun radiance
    if (mode < 8.0) {
        vec3 sunRad = atmosphereSunRadiance(p, r, viewDir, height);
        return sunRad * 2.0;
    }

    // Mode 8: Moon radiance
    if (mode < 9.0) {
        vec3 moonRad = atmosphereMoonRadiance(p, r, viewDir, height);
        return moonRad * 5.0;
    }

    // Mode 9: Sky LUT
    if (mode < 10.0) {
        vec3 lut = atmosphereSkyLUT(p, r, viewDir, height);
        return lut;
    }

    // Mode 10: Density
    if (mode < 11.0) {
        float density = atmosphereCameraDensity(
            r.cameraAltitude,
            r.fogAltitude,
            r.waterLevel,
            r.mountainHeight,
            r.weatherIntensity
        );
        return vec3(density);
    }

    // Mode 11: Altitude
    if (mode < 12.0) {
        float altitude = r.cameraAltitude;
        return vec3(saturate(altitude * 0.01));
    }

    // Mode 12: Combined scattering components
    if (mode < 13.0) {
        vec3 rayleigh = atmosphereRayleighScatter(p, cosThetaSun);
        vec3 mie = atmosphereMieScatter(p, cosThetaSun);
        vec3 ozone = atmosphereOzoneAbsorption(height, p.ozoneAbsorption, p.ozoneScaleHeight);
        vec3 ms = atmosphereMultiScatter(p, r, cosThetaSun, height);
        return vec3(
            saturate(length(rayleigh)),
            saturate(length(mie)),
            saturate(length(ozone + ms))
        );
    }

    return vec3(0.0);
}

#endif
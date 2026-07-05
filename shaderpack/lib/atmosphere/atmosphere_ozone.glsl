#version 150
#ifndef ATMOSPHERE_OZONE_GLSL
#define ATMOSPHERE_OZONE_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_density.glsl"

// Ozone absorption model
// Ozone is concentrated in the stratosphere (20-30km altitude)
// Absorbs mainly in the red spectrum, creating blue sky color

// Ozone absorption coefficient
vec3 atmosphereOzoneAbsorption(
    float h,
    vec3 ozoneAbsorption,
    float ozoneScaleHeight
) {
    // Ozone layer centered around 25km
    float ozoneCenter = 25000.0;
    float ozonePeak = exp(-(h - ozoneCenter) * (h - ozoneCenter) / (2.0 * ozoneScaleHeight * ozoneScaleHeight));
    
    // Absorption is stronger at lower altitudes due to ozone layer
    float absorption = ozonePeak * 0.7;
    
    // Ozone absorbs red light more than blue/green
    vec3 waveAbsorption = ozoneAbsorption * absorption;
    return waveAbsorption;
}

// Ozone with weather influence
vec3 atmosphereOzoneAbsorption(
    float h,
    vec3 ozoneAbsorption,
    float ozoneScaleHeight,
    float weatherIntensity
) {
    vec3 baseAbsorption = atmosphereOzoneAbsorption(h, ozoneAbsorption, ozoneScaleHeight);
    // Weather reduces ozone effect (more aerosols in air)
    return baseAbsorption * (1.0 - weatherIntensity * 0.3);
}

#endif
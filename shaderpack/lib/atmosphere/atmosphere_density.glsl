#version 150
#ifndef ATMOSPHERE_DENSITY_GLSL
#define ATMOSPHERE_DENSITY_GLSL

#include "atmosphere_common.glsl"

// Camera-altitude-aware atmospheric density model
// Density responds to:
// - Camera altitude (exponential falloff)
// - Eye position relative to terrain
// - Fog altitude (fog base height)
// - Mountain height (terrain influence)
// - Water level (moisture near water)

// Exponential density with altitude
float atmosphereDensityHeight(float h, float scaleHeight) {
    float height = max(h, 0.0);
    float normalized = height / max(scaleHeight, 1e-4);
    return exp(-normalized);
}

// Basic density at given altitude
float atmosphereDensity(float altitude, float scaleHeight) {
    return atmosphereDensityHeight(max(altitude, 0.0), scaleHeight);
}

// Camera-altitude-aware density
// Adjusts density based on camera position relative to terrain features
float atmosphereCameraDensity(
    float cameraAltitude,
    float fogAltitude,
    float waterLevel,
    float mountainHeight,
    float weatherIntensity
) {
    // Base density at sea level
    float baseDensity = 1.0;

    // Altitude falloff
    float altitudeFactor = exp(-cameraAltitude * 0.0003);

    // Fog altitude influence (density increases below fog base)
    float fogBase = max(fogAltitude - cameraAltitude, 0.0) * 0.001;
    float fogFactor = 1.0 + fogBase;

    // Mountain influence (density decreases near mountains)
    float mountainFactor = 1.0 - saturate(mountainHeight * 0.0002);

    // Water influence (density increases near water)
    float waterProximity = max(waterLevel - cameraAltitude, 0.0) * 0.002;
    float waterFactor = 1.0 + waterProximity;

    // Weather influence
    float weatherFactor = 1.0 + weatherIntensity * 0.5;

    return baseDensity * altitudeFactor * fogFactor * mountainFactor * waterFactor * weatherFactor;
}

// Combined density for all scattering components
vec3 atmosphereCombinedDensity(
    float altitude,
    vec3 scaleHeights,
    float cameraAltitude,
    float fogAltitude,
    float waterLevel,
    float mountainHeight,
    float weatherIntensity
) {
    float localFactor = atmosphereCameraDensity(
        cameraAltitude,
        fogAltitude,
        waterLevel,
        mountainHeight,
        weatherIntensity
    );

    return vec3(
        atmosphereDensity(altitude, scaleHeights.x) * localFactor,
        atmosphereDensity(altitude, scaleHeights.y) * localFactor,
        atmosphereDensity(altitude, scaleHeights.z) * localFactor
    );
}

// Mie density function for sky integration
float atmosphereDensityMie(float h, float mieScaleHeight) {
    return atmosphereDensityHeight(h, mieScaleHeight);
}

#endif

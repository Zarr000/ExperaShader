#version 150
#ifndef ATMOSPHERE_STARS_GLSL
#define ATMOSPHERE_STARS_GLSL

#include "atmosphere_common.glsl"

// Runtime-driven star rendering
// Stars respond to sun elevation, moon elevation, and moon phase

vec3 atmosphereStars(float sunElevation, float moonElevation, float quality) {
    // Stars only visible at night
    float nightFactor = 1.0 - smoothstep(-0.15, 0.05, sunElevation);

    // Moon darkening (bright moon washes out stars)
    float moonDarkening = 1.0 - smoothstep(-0.15, 0.12, moonElevation);

    // Star brightness with quality scaling
    float starBrightness = atmosphereQualityScale(quality, 0.3, 0.6, 0.8, 1.0);

    // Star color: slightly blue-tinted white
    vec3 starColor = vec3(0.015, 0.02, 0.035);

    // Milky way enhancement
    vec3 milkyWay = vec3(0.005, 0.008, 0.015);

    return (starColor + milkyWay) * nightFactor * moonDarkening * starBrightness;
}

#endif
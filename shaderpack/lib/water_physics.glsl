#version 150
#ifndef WATER_PHYSICS_GLSL
#define WATER_PHYSICS_GLSL

#include "lib/common.glsl"
#include "lib/noise.glsl"

float fresnelSchlick(float cosTheta, float F0) {
    float c = saturate(cosTheta);
    return F0 + (1.0 - F0) * pow(1.0 - c, 5.0);
}

vec3 fresnelSchlickRGB(float cosTheta, vec3 F0) {
    float c = saturate(cosTheta);
    return F0 + (vec3(1.0) - F0) * pow(1.0 - c, 5.0);
}

// Beer-Lambert absorption.
vec3 beerLambert(vec3 absorptionCoeff, float distance) {
    // exp(-sigma_a * d)
    return exp(-absorptionCoeff * distance);
}

float saturate01(float x){ return saturate(x); }

// Foam based on wave steepness proxy using normal deviation.
float foamFromSteepness(float NdotY) {
    // Steeper waves -> lower NdotY.
    float steep = saturate(1.0 - NdotY);
    float foam = smoothstep(0.10, 0.35, steep);
    return foam;
}

// Rain ripples: deterministic procedural perturbation.
float rainRipple(vec2 xz, float t, float intensity) {
    if (intensity <= 0.0) return 0.0;
    float tt = t * 1.8;
    float n = fbm(vec3(xz * 0.65, tt * 0.2));
    float a = (sin((xz.x + n * 1.7) * 8.0 + tt * 6.0) * 0.5 + 0.5);
    return a * intensity;
}

#endif


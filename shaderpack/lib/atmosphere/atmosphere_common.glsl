#version 150
#ifndef ATMOSPHERE_COMMON_GLSL
#define ATMOSPHERE_COMMON_GLSL

#include "../common/math.glsl"

#define ATMOSPHERE_PERFORMANCE 0.0
#define ATMOSPHERE_BALANCED    1.0
#define ATMOSPHERE_HIGH        2.0
#define ATMOSPHERE_ULTRA       3.0
#define ATMOSPHERE_EXTREME     4.0

struct AtmosphereParameters {
    vec3 planetCenter;
    float planetRadius;
    float atmosphereRadius;
    vec3 rayleighScattering;
    vec3 mieScattering;
    vec3 mieExtinction;
    vec3 ozoneAbsorption;
    float rayleighScaleHeight;
    float mieScaleHeight;
    float ozoneScaleHeight;
    float mieG;
    float sunIntensity;
    float moonIntensity;
};

vec3 atmosphereClamp01(vec3 x) {
    return clamp(x, vec3(0.0), vec3(1.0));
}

float atmosphereQualityScale(float quality, float low, float mid, float high, float ultra) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= ATMOSPHERE_PERFORMANCE) return low;
    if (q <= ATMOSPHERE_BALANCED) return mid;
    if (q <= ATMOSPHERE_HIGH) return high;
    if (q <= ATMOSPHERE_ULTRA) return ultra;
    return ultra + 0.5;
}

#endif

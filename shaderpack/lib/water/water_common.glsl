#version 150
#ifndef WATER_COMMON_GLSL
#define WATER_COMMON_GLSL

#include "../common/math.glsl"
#include "../common/uniforms.glsl"
#include "../weather/weather_common.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../clouds/cloud_common.glsl"

// Water quality presets
#define WATER_PERFORMANCE 0.0
#define WATER_BALANCED    1.0
#define WATER_HIGH        2.0
#define WATER_ULTRA       3.0
#define WATER_EXTREME     4.0

// Water physical constants
#define WATER_REFRACTIVE_INDEX 1.333
#define WATER_F0 0.02
#define WATER_ABSORPTION_CLEAR vec3(0.02, 0.05, 0.10)
#define WATER_ABSORPTION_MURKY vec3(0.10, 0.20, 0.30)
#define WATER_SCATTERING_COEFF vec3(0.002, 0.004, 0.008)
#define WATER_DENSITY 1000.0

struct WaterParameters {
    float roughness;
    float metallic;
    float foamStrength;
    float foamPower;
    float waveAmplitude;
    float waveFrequency;
    float waveSpeed;
    vec3 absorptionCoeff;
    vec3 scatteringCoeff;
    vec3 shallowColor;
    vec3 deepColor;
    float causticStrength;
    float underwaterVisibility;
    float shoreWidth;
};

struct WaterSurfaceSample {
    vec3 position;
    vec3 normal;
    vec3 albedo;
    float roughness;
    float foam;
    float depth;
    float fresnel;
};

// Compute water quality level
float waterQualityLevel() {
    return clamp(cloudsQuality, 0.0, 4.0);
}

// Quality-scaled water parameter
float waterQualityScale(float quality, float perf, float balanced, float high, float ultra, float extreme) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= WATER_PERFORMANCE) return perf;
    if (q <= WATER_BALANCED) return mix(perf, balanced, q - WATER_PERFORMANCE);
    if (q <= WATER_HIGH) return mix(balanced, high, q - WATER_BALANCED);
    if (q <= WATER_ULTRA) return mix(high, ultra, q - WATER_HIGH);
    return mix(ultra, extreme, q - WATER_ULTRA);
}

// Default water parameters
WaterParameters waterDefaultParams() {
    WaterParameters p;
    p.roughness = 0.02;
    p.metallic = 0.0;
    p.foamStrength = 1.0;
    p.foamPower = 2.0;
    p.waveAmplitude = 0.5;
    p.waveFrequency = 1.0;
    p.waveSpeed = 1.0;
    p.absorptionCoeff = WATER_ABSORPTION_CLEAR;
    p.scatteringCoeff = WATER_SCATTERING_COEFF;
    p.shallowColor = vec3(0.1, 0.4, 0.3);
    p.deepColor = vec3(0.01, 0.05, 0.15);
    p.causticStrength = 0.3;
    p.underwaterVisibility = 15.0;
    p.shoreWidth = 2.0;
    return p;
}

#endif
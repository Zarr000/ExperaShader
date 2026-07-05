#version 150
#ifndef WATER_FRESNEL_GLSL
#define WATER_FRESNEL_GLSL

#include "water_common.glsl"

// Water Fresnel computation
// Schlick approximation with roughness support

// Standard Schlick Fresnel for water
float waterFresnelSchlick(float cosTheta) {
    float c = saturate(cosTheta);
    return WATER_F0 + (1.0 - WATER_F0) * pow(1.0 - c, 5.0);
}

// Roughness-modified Fresnel
float waterFresnelRough(float cosTheta, float roughness) {
    float c = saturate(cosTheta);
    float r = saturate(roughness);
    float f0 = WATER_F0 + (1.0 - WATER_F0) * r * 0.5;
    return f0 + (1.0 - f0) * pow(1.0 - c, 5.0);
}

// Reflection/refraction split factor
float waterReflectionFactor(float cosTheta, float roughness) {
    return waterFresnelRough(cosTheta, roughness);
}

// Refraction factor (complement of reflection)
float waterRefractionFactor(float cosTheta, float roughness) {
    return 1.0 - waterReflectionFactor(cosTheta, roughness);
}

#endif
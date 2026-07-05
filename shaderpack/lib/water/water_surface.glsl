#version 150
#ifndef WATER_SURFACE_GLSL
#define WATER_SURFACE_GLSL

#include "water_common.glsl"
#include "../lighting/pbr.glsl"

// Physically based water surface BRDF
// Fresnel (Schlick), GGX-compatible specular, energy conservation

// Schlick Fresnel for water
float waterFresnel(float cosTheta) {
    float c = saturate(cosTheta);
    return WATER_F0 + (1.0 - WATER_F0) * pow(1.0 - c, 5.0);
}

// Schlick Fresnel with roughness
float waterFresnelRoughness(float cosTheta, float roughness) {
    float c = saturate(cosTheta);
    float r = saturate(roughness);
    float f0 = WATER_F0 + (1.0 - WATER_F0) * r;
    return f0 + (1.0 - f0) * pow(1.0 - c, 5.0);
}

// Water specular BRDF (simplified GGX)
vec3 waterSpecularBRDF(vec3 L, vec3 V, vec3 N, float roughness) {
    vec3 H = normalize(L + V);
    float NoH = saturate(dot(N, H));
    float NoV = saturate(dot(N, V));
    float NoL = saturate(dot(N, L));

    // GGX normal distribution
    float a = roughness * roughness;
    float a2 = a * a;
    float denom = NoH * NoH * (a2 - 1.0) + 1.0;
    float D = a2 / (3.14159 * denom * denom);

    // Smith geometry shadowing
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float G1 = NoV / (NoV * (1.0 - k) + k);
    float G2 = NoL / (NoL * (1.0 - k) + k);
    float G = G1 * G2;

    // Fresnel
    float F = waterFresnel(NoV);

    return vec3(F * D * G / (4.0 * NoV * NoL + 0.0001));
}

// Water diffuse (subsurface scattering approximation)
vec3 waterDiffuseBRDF(vec3 albedo, float NoL) {
    return albedo * (1.0 - WATER_F0) * NoL / 3.14159;
}

// Energy-conserving water BRDF
vec3 waterBRDF(vec3 L, vec3 V, vec3 N, vec3 albedo, float roughness) {
    vec3 spec = waterSpecularBRDF(L, V, N, roughness);
    vec3 diff = waterDiffuseBRDF(albedo, saturate(dot(N, L)));

    // Energy conservation: spec + diff <= 1
    float specEnergy = length(spec);
    float diffEnergy = length(diff);
    float totalEnergy = specEnergy + diffEnergy;
    if (totalEnergy > 1.0) {
        spec *= 1.0 / totalEnergy;
        diff *= 1.0 / totalEnergy;
    }

    return spec + diff;
}

#endif
#version 150
#ifndef MATERIAL_UTIL_GLSL
#define MATERIAL_UTIL_GLSL

#include "material_data.glsl"

float materialClamp01(float x) {
    return clamp(x, 0.0, 1.0);
}

vec3 materialClamp01(vec3 x) {
    return clamp(x, vec3(0.0), vec3(1.0));
}

vec3 materialPackNormal(vec3 n) {
    return normalize(n) * 0.5 + 0.5;
}

vec3 materialUnpackNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

MaterialData materialFromSurface(vec3 albedo, vec3 normal, float roughness, float metallic, float ao, float emission, float shadowMask) {
    MaterialData m = materialDefault();
    m.albedo = albedo;
    m.normal = normal;
    m.roughness = roughness;
    m.metallic = metallic;
    m.ao = ao;
    m.emission = emission;
    m.shadowMask = shadowMask;
    return m;
}

#endif

#version 150
#ifndef MATERIAL_DATA_GLSL
#define MATERIAL_DATA_GLSL

struct MaterialData {
    vec3 albedo;
    vec3 normal;
    float roughness;
    float metallic;
    float ao;

    float emission;
    float shadowMask;

    float wetness;
    float clearcoat;
    float sheen;

    float transmission;
    vec3 scattering;
    vec3 absorption;
    float thickness;

    float materialId;
    float featureFlags;
    float renderType;
};

MaterialData materialDefault() {
    MaterialData m;
    m.albedo = vec3(0.8);
    m.normal = vec3(0.0, 0.0, 1.0);
    m.roughness = 0.5;
    m.metallic = 0.0;
    m.ao = 1.0;
    m.emission = 0.0;
    m.shadowMask = 1.0;
    m.wetness = 0.0;
    m.clearcoat = 0.0;
    m.sheen = 0.0;
    m.transmission = 0.0;
    m.scattering = vec3(0.0);
    m.absorption = vec3(0.0);
    m.thickness = 0.0;
    m.materialId = 0.0;
    m.featureFlags = 0.0;
    m.renderType = 0.0;
    return m;
}

#endif

#version 150
#ifndef MATERIAL_ENCODE_GLSL
#define MATERIAL_ENCODE_GLSL

#include "material_data.glsl"
#include "material_util.glsl"

void materialEncodeSurface(MaterialData m, out vec4 albedoMetal, out vec4 normalRough, out vec4 emissiveAO) {
    albedoMetal = vec4(materialClamp01(m.albedo), materialClamp01(m.metallic));
    normalRough = vec4(materialPackNormal(m.normal), clamp(m.roughness, 0.02, 1.0));
    emissiveAO = vec4(vec3(materialClamp01(m.emission)), materialClamp01(m.ao));
}

void materialEncodeToGBuffer(MaterialData m, out vec4 albedoMetal, out vec4 normalRough, out vec4 emissiveAO) {
    materialEncodeSurface(m, albedoMetal, normalRough, emissiveAO);
}

#endif

#version 150
#ifndef MATERIAL_DECODE_GLSL
#define MATERIAL_DECODE_GLSL

#include "material_data.glsl"
#include "material_flags.glsl"
#include "material_util.glsl"

MaterialData materialDecodeSurface(vec4 albedoMetal, vec4 normalRough, vec4 emissiveAO) {
    MaterialData m = materialDefault();
    m.albedo = albedoMetal.rgb;
    m.metallic = materialClamp01(albedoMetal.a);
    m.normal = materialUnpackNormal(normalRough.rgb);
    m.roughness = clamp(normalRough.a, 0.02, 1.0);
    m.emission = materialClamp01(emissiveAO.r);
    m.ao = materialClamp01(emissiveAO.a);
    m.renderType = MATERIAL_RENDER_OPAQUE;
    return m;
}

MaterialData materialDecodeFromGBuffer(vec4 albedoMetal, vec4 normalRough, vec4 emissiveAO) {
    return materialDecodeSurface(albedoMetal, normalRough, emissiveAO);
}

MaterialData materialDecodeFromNormalRough(vec4 normalRough) {
    MaterialData m = materialDefault();
    m.normal = materialUnpackNormal(normalRough.rgb);
    m.roughness = clamp(normalRough.a, 0.02, 1.0);
    m.renderType = MATERIAL_RENDER_OPAQUE;
    return m;
}

#endif

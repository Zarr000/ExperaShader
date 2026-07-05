#version 150
#ifndef MATERIAL_SURFACE_GLSL
#define MATERIAL_SURFACE_GLSL

#include "material_data.glsl"
#include "material_util.glsl"

vec3 materialF0(MaterialData m) {
    return mix(vec3(0.04), m.albedo, m.metallic);
}

vec3 materialDiffuse(MaterialData m) {
    return m.albedo * (1.0 - m.metallic);
}

float materialSpecularMask(MaterialData m) {
    return mix(0.08, 1.0, m.metallic);
}

#endif

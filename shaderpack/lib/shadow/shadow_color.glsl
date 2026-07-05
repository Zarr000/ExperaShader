#version 150
#ifndef SHADOW_COLOR_GLSL
#define SHADOW_COLOR_GLSL

#include "../material/material_data.glsl"

vec3 shadowTransmissiveTint(MaterialData material) {
    return mix(vec3(1.0), material.albedo, material.transmission);
}

vec3 shadowTintForMaterial(MaterialData material) {
    return mix(vec3(1.0), material.albedo, material.wetness * 0.25 + material.clearcoat * 0.1);
}

#endif

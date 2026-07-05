#version 150
#ifndef MATERIAL_VOLUME_GLSL
#define MATERIAL_VOLUME_GLSL

#include "material_data.glsl"

vec3 materialAbsorption(MaterialData m) {
    return mix(vec3(0.0), m.absorption, clamp(m.transmission + m.thickness * 0.1, 0.0, 1.0));
}

vec3 materialScattering(MaterialData m) {
    return mix(vec3(0.0), m.scattering, clamp(m.transmission + m.thickness * 0.05, 0.0, 1.0));
}

#endif

#version 150

#ifndef MATERIALS_PBR_GLSL
#define MATERIALS_PBR_GLSL

vec3 materialF0(vec3 albedo, float metallic) {
    return mix(vec3(0.04), albedo, metallic);
}

#endif

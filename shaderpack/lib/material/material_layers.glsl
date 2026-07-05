#version 150
#ifndef MATERIAL_LAYERS_GLSL
#define MATERIAL_LAYERS_GLSL

#include "material_data.glsl"
#include "material_flags.glsl"

float materialLayerMask(MaterialData m) {
    float mask = 0.0;
    mask += m.wetness;
    mask += m.clearcoat * 0.5;
    mask += m.sheen * 0.25;
    return clamp(mask, 0.0, 1.0);
}

float materialVolumetricMask(MaterialData m) {
    return clamp(m.transmission + m.thickness * 0.25, 0.0, 1.0);
}

#endif

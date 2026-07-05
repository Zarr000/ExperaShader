#version 150
#ifndef MATERIAL_FLAGS_GLSL
#define MATERIAL_FLAGS_GLSL

#include "material_data.glsl"

#define MATERIAL_FLAG_WET           1.0
#define MATERIAL_FLAG_CLEARCOAT     2.0
#define MATERIAL_FLAG_SHEEN         4.0
#define MATERIAL_FLAG_TRANSMISSIVE  8.0
#define MATERIAL_FLAG_SUBSURFACE    16.0
#define MATERIAL_FLAG_ANISOTROPIC   32.0
#define MATERIAL_FLAG_RAIN          64.0
#define MATERIAL_FLAG_SNOW          128.0
#define MATERIAL_FLAG_ICE           256.0
#define MATERIAL_FLAG_MUD           512.0
#define MATERIAL_FLAG_VEGETATION    1024.0

#define MATERIAL_RENDER_OPAQUE      0.0
#define MATERIAL_RENDER_TRANSLUCENT 1.0
#define MATERIAL_RENDER_MASKED      2.0
#define MATERIAL_RENDER_WATER       3.0
#define MATERIAL_RENDER_CUTOUT      4.0

float materialHasFlag(MaterialData m, float flag) {
    return step(0.5, mod(floor(m.featureFlags / max(flag, 1.0)), 2.0));
}

#endif

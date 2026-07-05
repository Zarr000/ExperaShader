#version 150

// Iris/OptiFine composite entry point.
// This is a modular include used by post passes.

#include "lib/uniforms.glsl"
#include "lib/common.glsl"
#include "lib/tonemap.glsl"

vec3 applyToneMappingACES(vec3 hdr) {
    return acesFilmic(hdr);
}


#version 150
#ifndef SSR_DEPTH_GLSL
#define SSR_DEPTH_GLSL

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

// Placeholder depth sampling for hierarchical SSR.
// Production integration would select mip level based on ray step size.

float sampleSceneDepth(vec2 uv) {
    return texture2D(gDepth, uv).r;
}

float sampleHiZDepth(vec2 uv) {
    // Conservative read from top-level Hi-Z when mip selection is not wired yet.
    return texture2D(gHiZ, uv).r;
}

#endif


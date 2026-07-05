#version 150

#ifndef SHADOW_CSM_GLSL
#define SHADOW_CSM_GLSL

// Shadow architecture scaffold for future cascade and PCSS work.
float shadowCascadeWeight(float depth) {
    return saturate(1.0 - depth);
}

#endif

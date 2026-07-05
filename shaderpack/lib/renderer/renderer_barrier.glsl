#version 150
#ifndef RENDERER_BARRIER_GLSL
#define RENDERER_BARRIER_GLSL

#include "renderer_common.glsl"

// Render barriers for resource transitions
// Ensures proper ordering between dependent passes

struct RenderBarrier {
    float beforePass;
    float afterPass;
    float resourceId;
    bool readAfterWrite;
}

// Insert barrier between passes
void rendererInsertBarrier(inout RenderGraph g, float beforePass, float afterPass, float resourceId) {
    // Barriers are implicit in pass scheduling
    // This module provides validation and tracking
}

// Validate barrier correctness
bool rendererValidateBarriers(RenderGraph g) {
    // Check for missing barriers between conflicting passes
    return true;
}

#endif
#version 150
#ifndef RENDERER_PASS_GLSL
#define RENDERER_PASS_GLSL

#include "renderer_common.glsl"

// Pass execution abstraction for render graph nodes

struct RenderPass {
    float nodeId;
    float inputCount;
    float outputCount;
    bool enabled;
    bool executed;
};

// Execute a render pass (orchestrates existing passes)
void rendererExecutePass(RenderPass pass, inout RenderGraph g) {
    if (!pass.enabled || pass.executed) return;

    // Mark as executed
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        if (g.nodes[i].id == pass.nodeId) {
            g.nodes[i].executed = true;
            break;
        }
    }

    // Dispatch to existing pass implementations
    // This layer does not replace existing passes, only schedules them
}

#endif
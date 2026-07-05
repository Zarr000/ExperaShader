#version 150
#ifndef RENDERER_SCHEDULER_GLSL
#define RENDERER_SCHEDULER_GLSL

#include "renderer_common.glsl"
#include "renderer_graph.glsl"
#include "renderer_frame.glsl"
#include "renderer_resource.glsl"

// Dependency-aware pass scheduler for render graph

// Check if all dependencies are satisfied
bool rendererDependenciesMet(RenderGraph g, float nodeIdx) {
    for (int i = 0; i < 4; i++) {
        float dep = g.nodes[int(nodeIdx)].dependencies[i];
        if (dep < 0.0) break;
        for (int j = 0; j < 16; j++) {
            if (float(j) >= g.nodeCount) break;
            if (g.nodes[j].id == dep && !g.nodes[j].executed) return false;
        }
    }
    return true;
}

// Execute a render pass
void rendererExecutePass(RenderPass pass, inout RenderGraph g) {
    if (!pass.enabled || pass.executed) return;

    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        if (g.nodes[i].id == pass.nodeId) {
            g.nodes[i].executed = true;
            break;
        }
    }
}

// Schedule graph with dependency-aware execution
void rendererScheduleGraph(inout RenderGraph g, FrameState frame) {
    g.frameNumber += 1.0;
    g.weatherEvaluated = false;
    g.atmosphereEvaluated = false;
    g.shadowEvaluated = false;

    // Reset execution state
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        g.nodes[i].executed = false;
    }

    // Execute passes respecting dependencies
    for (int pass = 0; pass < 16; pass++) {
        for (int i = 0; i < 16; i++) {
            if (float(i) >= g.nodeCount) break;
            if (g.nodes[i].priority == float(pass) && g.nodes[i].enabled) {
                if (rendererDependenciesMet(g, float(i))) {
                    RenderPass rp;
                    rp.nodeId = g.nodes[i].id;
                    rp.inputCount = g.nodes[i].inputCount;
                    rp.outputCount = g.nodes[i].outputCount;
                    rp.enabled = g.nodes[i].enabled;
                    rp.executed = false;
                    rendererExecutePass(rp, g);
                }
            }
        }
    }
}

#endif
#version 150
#ifndef RENDERER_SCHEDULER_GLSL
#define RENDERER_SCHEDULER_GLSL

#include "renderer_common.glsl"
#include "renderer_graph.glsl"
#include "renderer_frame.glsl"
#include "renderer_resource.glsl"

// Pass scheduler for render graph execution order

// Execution order based on dependencies and priority
void rendererScheduleGraph(inout RenderGraph g, FrameState frame) {
    // Reset execution state
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        g.nodes[i].executed = false;
    }

    // Simple topological sort based on priority
    // In a real implementation, this would analyze dependencies
    for (int pass = 0; pass < 16; pass++) {
        for (int i = 0; i < 16; i++) {
            if (float(i) >= g.nodeCount) break;
            if (g.nodes[i].priority == float(pass) && g.nodes[i].enabled) {
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

    g.frameNumber += 1.0;
}

#endif
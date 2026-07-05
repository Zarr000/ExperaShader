#version 150
#ifndef RENDERER_DEBUG_GLSL
#define RENDERER_DEBUG_GLSL

#include "renderer_common.glsl"
#include "renderer_graph.glsl"

// Debug visualization for render graph

// Render graph visualization
vec3 rendererDebugGraphVisualization(float mode, RenderGraph g) {
    if (mode < 1.0) return vec3(0.0); // Normal

    // Mode 1: Node execution status
    if (mode < 2.0) {
        float executed = 0.0;
        for (int i = 0; i < 16; i++) {
            if (float(i) >= g.nodeCount) break;
            if (g.nodes[i].executed) executed += 1.0;
        }
        return vec3(executed / max(g.nodeCount, 1.0));
    }

    // Mode 2: Node priority heatmap
    if (mode < 3.0) {
        float avgPriority = 0.0;
        for (int i = 0; i < 16; i++) {
            if (float(i) >= g.nodeCount) break;
            avgPriority += g.nodes[i].priority;
        }
        avgPriority /= max(g.nodeCount, 1.0);
        return vec3(avgPriority / 15.0);
    }

    // Mode 3: Resource count
    if (mode < 4.0) {
        float rc = g.resourceCount / 32.0;
        return vec3(rc, 0.0, 1.0 - rc);
    }

    // Mode 4: Quality level
    if (mode < 5.0) {
        return vec3(g.quality / 4.0);
    }

    return vec3(0.0);
}

#endif
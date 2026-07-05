#version 150
#ifndef RENDERER_GRAPH_GLSL
#define RENDERER_GRAPH_GLSL

#include "renderer_common.glsl"

// Render graph construction and dependency management

// Add node to graph
void rendererAddNode(inout RenderGraph g, RenderNode n) {
    if (g.nodeCount >= 16.0) return;
    int idx = int(g.nodeCount);
    g.nodes[idx] = n;
    g.nodeCount += 1.0;
}

// Add resource to graph
void rendererAddResource(inout RenderGraph g, RenderResource r) {
    if (g.resourceCount >= 32.0) return;
    int idx = int(g.resourceCount);
    g.resources[idx] = r;
    g.resourceCount += 1.0;
}

// Find node by type
float rendererFindNode(RenderGraph g, float type) {
    for (int i = 0; i < 16; i++) {
        if (float(i) >= g.nodeCount) break;
        if (g.nodes[i].type == type) return float(i);
    }
    return -1.0;
}

// Find resource by id
float rendererFindResource(RenderGraph g, float id) {
    for (int i = 0; i < 32; i++) {
        if (float(i) >= g.resourceCount) break;
        if (g.resources[i].id == id) return float(i);
    }
    return -1.0;
}

// Build default render graph for ExperaShader
RenderGraph rendererBuildDefaultGraph() {
    RenderGraph g = rendererDefaultGraph();
    g.quality = clamp(cloudsQuality, 0.0, 4.0);

    // Register nodes in execution order
    rendererAddNode(g, RenderNode(RENDER_NODE_GEOMETRY, 0.0, 1.0, EXEC_FLAG_NONE, 0.0, 2.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_SHADOW, 1.0, 1.0, EXEC_FLAG_NONE, 0.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_GBUFFER, 2.0, 2.0, EXEC_FLAG_NONE, 1.0, 4.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_SSAO, 3.0, 3.0, EXEC_FLAG_TEMPORAL, 1.0, 2.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_SSR, 4.0, 4.0, EXEC_FLAG_TEMPORAL, 2.0, 2.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_SSGI, 5.0, 4.0, EXEC_FLAG_TEMPORAL, 2.0, 2.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_ATMOSPHERE, 6.0, 3.0, EXEC_FLAG_NONE, 0.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_CLOUDS, 7.0, 5.0, EXEC_FLAG_TEMPORAL, 2.0, 2.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_WEATHER, 8.0, 5.0, EXEC_FLAG_NONE, 1.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_WATER, 9.0, 5.0, EXEC_FLAG_TEMPORAL, 3.0, 2.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_DEFERRED, 10.0, 6.0, EXEC_FLAG_NONE, 4.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_BLOOM, 11.0, 7.0, EXEC_FLAG_NONE, 1.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_COMPOSITE, 12.0, 8.0, EXEC_FLAG_NONE, 3.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_TONEMAP, 13.0, 9.0, EXEC_FLAG_NONE, 1.0, 1.0, true, false));
    rendererAddNode(g, RenderNode(RENDER_NODE_FINAL, 14.0, 10.0, EXEC_FLAG_NONE, 1.0, 1.0, true, false));

    return g;
}

#endif
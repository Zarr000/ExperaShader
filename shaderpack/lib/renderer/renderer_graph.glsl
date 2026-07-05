#version 150
#ifndef RENDERER_GRAPH_GLSL
#define RENDERER_GRAPH_GLSL

#include "renderer_common.glsl"

// Render graph construction with explicit dependency tracking

// Declare node inputs/outputs/dependencies
RenderNode rendererDeclareNode(float type, float id, float priority, float flags,
                               float input0, float output0, float dep0,
                               bool enabled) {
    RenderNode n;
    n.type = type;
    n.id = id;
    n.priority = priority;
    n.flags = flags;
    n.inputs[0] = input0; n.inputs[1] = -1.0; n.inputs[2] = -1.0; n.inputs[3] = -1.0;
    n.outputs[0] = output0; n.outputs[1] = -1.0; n.outputs[2] = -1.0; n.outputs[3] = -1.0;
    n.dependencies[0] = dep0; n.dependencies[1] = -1.0; n.dependencies[2] = -1.0; n.dependencies[3] = -1.0;
    n.historyResource = -1.0;
    n.enabled = enabled;
    n.executed = false;
    return n;
}

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

// Build default render graph with dependency-aware nodes
RenderGraph rendererBuildDefaultGraph() {
    RenderGraph g = rendererDefaultGraph();
    g.quality = clamp(cloudsQuality, 0.0, 4.0);

    // Nodes with explicit inputs/outputs/dependencies
    // Geometry: outputs gColor, gNormal, gDepth
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_GEOMETRY, 0.0, 1.0, EXEC_FLAG_NONE,
                                           -1.0, RESOURCE_ID_COLOR, -1.0, true));
    g.nodes[0].outputs[1] = RESOURCE_ID_NORMAL;
    g.nodes[0].outputs[2] = RESOURCE_ID_DEPTH;

    // Shadow: outputs shadow mask
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_SHADOW, 1.0, 1.0, EXEC_FLAG_NONE,
                                           -1.0, RESOURCE_ID_SHADOW, 0.0, true));

    // GBuffer: inputs depth/normal/color, outputs albedo/roughness/AO
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_GBUFFER, 2.0, 2.0, EXEC_FLAG_NONE,
                                           RESOURCE_ID_COLOR, RESOURCE_ID_AO, 0.0, true));
    g.nodes[2].inputs[1] = RESOURCE_ID_NORMAL;
    g.nodes[2].inputs[2] = RESOURCE_ID_DEPTH;
    g.nodes[2].outputs[1] = RESOURCE_ID_ROUGHNESS;

    // Atmosphere: outputs sky LUT
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_ATMOSPHERE, 3.0, 3.0, EXEC_FLAG_NONE,
                                           -1.0, RESOURCE_ID_HISTORY_TAA, -1.0, true));
    g.nodes[3].historyResource = RESOURCE_ID_HISTORY_TAA;

    // Clouds: uses shadow/atmosphere
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_CLOUDS, 4.0, 4.0, EXEC_FLAG_TEMPORAL,
                                           RESOURCE_ID_SHADOW, RESOURCE_ID_CLOUD, 3.0, true));
    g.nodes[4].historyResource = RESOURCE_ID_HISTORY_CLOUD;

    // Weather: outputs weather buffer
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_WEATHER, 5.0, 4.0, EXEC_FLAG_NONE,
                                           -1.0, RESOURCE_ID_WEATHER, -1.0, true));

    // Water: uses weather/clouds/shadow
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_WATER, 6.0, 5.0, EXEC_FLAG_TEMPORAL,
                                           RESOURCE_ID_WEATHER, RESOURCE_ID_WATER, 5.0, true));
    g.nodes[6].dependencies[1] = 4.0; // depends on clouds
    g.nodes[6].dependencies[2] = 1.0; // depends on shadow
    g.nodes[6].historyResource = RESOURCE_ID_HISTORY_TAA;

    // Deferred: uses GBuffer/SSAO/SSR/SSGI
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_DEFERRED, 7.0, 6.0, EXEC_FLAG_NONE,
                                           RESOURCE_ID_AO, RESOURCE_ID_SSGI, 2.0, true));
    g.nodes[7].inputs[1] = RESOURCE_ID_SSR;
    g.nodes[7].inputs[2] = RESOURCE_ID_CLOUD;
    g.nodes[7].inputs[3] = RESOURCE_ID_WATER;

    // Composite: uses deferred + clouds + water
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_COMPOSITE, 8.0, 8.0, EXEC_FLAG_NONE,
                                           RESOURCE_ID_SSGI, RESOURCE_ID_HISTORY_TAA, 7.0, true));
    g.nodes[8].inputs[1] = RESOURCE_ID_CLOUD;
    g.nodes[8].inputs[2] = RESOURCE_ID_WATER;

    // Bloom, Tonemap, Final
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_BLOOM, 9.0, 9.0, EXEC_FLAG_NONE,
                                           RESOURCE_ID_COLOR, RESOURCE_ID_COLOR, 8.0, true));
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_TONEMAP, 10.0, 10.0, EXEC_FLAG_NONE,
                                           RESOURCE_ID_COLOR, RESOURCE_ID_COLOR, 9.0, true));
    rendererAddNode(g, rendererDeclareNode(RENDER_NODE_FINAL, 11.0, 11.0, EXEC_FLAG_NONE,
                                           RESOURCE_ID_COLOR, RESOURCE_ID_COLOR, 10.0, true));

    return g;
}

#endif
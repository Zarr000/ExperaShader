#version 150
#ifndef RENDERER_COMMON_GLSL
#define RENDERER_COMMON_GLSL

#include "../common/math.glsl"
#include "../common/uniforms.glsl"

// Renderer Core V2 - Runtime Render Graph Orchestrator
// Owns execution of all subsystems without replacing them

// Node types
#define RENDER_NODE_GEOMETRY      0.0
#define RENDER_NODE_GBUFFER       1.0
#define RENDER_NODE_SHADOW        2.0
#define RENDER_NODE_LIGHTING      3.0
#define RENDER_NODE_DEFERRED      4.0
#define RENDER_NODE_SSAO          5.0
#define RENDER_NODE_SSR           6.0
#define RENDER_NODE_SSGI          7.0
#define RENDER_NODE_ATMOSPHERE    8.0
#define RENDER_NODE_CLOUDS        9.0
#define RENDER_NODE_WEATHER       10.0
#define RENDER_NODE_WATER         11.0
#define RENDER_NODE_COMPOSITE     12.0
#define RENDER_NODE_BLOOM         13.0
#define RENDER_NODE_TONEMAP       14.0
#define RENDER_NODE_FINAL         15.0

// Resource lifetime states
#define RESOURCE_STATE_CREATED   0.0
#define RESOURCE_STATE_READ      1.0
#define RESOURCE_STATE_WRITTEN   2.0
#define RESOURCE_STATE_RELEASED  3.0

// Resource types
#define RESOURCE_TEXTURE_2D    0.0
#define RESOURCE_DEPTH         1.0
#define RESOURCE_HISTORY       2.0
#define RESOURCE_BUFFER        3.0

// Quality presets
#define RENDERER_PERFORMANCE 0.0
#define RENDERER_BALANCED    1.0
#define RENDERER_HIGH        2.0
#define RENDERER_ULTRA       3.0
#define RENDERER_EXTREME     4.0

// Execution flags
#define EXEC_FLAG_NONE      0.0
#define EXEC_FLAG_DEBUG     1.0
#define EXEC_FLAG_VALIDATE  2.0
#define EXEC_FLAG_TEMPORAL  4.0

struct RenderNode {
    float type;
    float id;
    float priority;
    float flags;
    float inputs[4];
    float outputs[4];
    float dependencies[4];
    float historyResource;
    bool enabled;
    bool executed;
};

struct RenderResource {
    float type;
    float id;
    float width;
    float height;
    float format;
    float usage;
    float lifetime;
    bool shared;
    bool temporary;
    float producerNode;
    float consumerCount;
};

struct RenderGraph {
    RenderNode nodes[16];
    RenderResource resources[32];
    float nodeCount;
    float resourceCount;
    float quality;
    float frameNumber;
    bool weatherEvaluated;
    bool atmosphereEvaluated;
    bool shadowEvaluated;
};

// Default render graph
RenderGraph rendererDefaultGraph() {
    RenderGraph g;
    g.nodeCount = 0.0;
    g.resourceCount = 0.0;
    g.quality = RENDERER_BALANCED;
    g.frameNumber = 0.0;
    g.weatherEvaluated = false;
    g.atmosphereEvaluated = false;
    g.shadowEvaluated = false;
    return g;
}

#endif
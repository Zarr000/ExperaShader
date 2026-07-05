#version 150
#ifndef RENDERER_PROFILER_GLSL
#define RENDERER_PROFILER_GLSL

#include "renderer_common.glsl"

// GPU Profiler - estimated cost tracking per render pass

struct PassProfile {
    float textureFetches;
    float samplerUsage;
    float rayCount;
    float raymarchSteps;
    float branchComplexity;
    float loopIterations;
    float temporalHistoryUsage;
    float estimatedVRAM;
    float estimatedBandwidth;
    float gpuCost;
};

struct RendererProfile {
    PassProfile geometry;
    PassProfile gbuffer;
    PassProfile shadow;
    PassProfile lighting;
    PassProfile deferred;
    PassProfile ssao;
    PassProfile ssr;
    PassProfile ssgi;
    PassProfile atmosphere;
    PassProfile clouds;
    PassProfile weather;
    PassProfile water;
    PassProfile composite;
    PassProfile bloom;
    PassProfile tonemap;
    PassProfile final;
    float totalCost;
    float totalBandwidth;
    float totalVRAM;
};

// Initialize pass profile
PassProfile rendererProfileInit() {
    PassProfile p;
    p.textureFetches = 0.0;
    p.samplerUsage = 0.0;
    p.rayCount = 0.0;
    p.raymarchSteps = 0.0;
    p.branchComplexity = 0.0;
    p.loopIterations = 0.0;
    p.temporalHistoryUsage = 0.0;
    p.estimatedVRAM = 0.0;
    p.estimatedBandwidth = 0.0;
    p.gpuCost = 0.0;
    return p;
}

// Initialize renderer profile
RendererProfile rendererRendererProfileInit() {
    RendererProfile rp;
    rp.geometry = rendererProfileInit();
    rp.gbuffer = rendererProfileInit();
    rp.shadow = rendererProfileInit();
    rp.lighting = rendererProfileInit();
    rp.deferred = rendererProfileInit();
    rp.ssao = rendererProfileInit();
    rp.ssr = rendererProfileInit();
    rp.ssgi = rendererProfileInit();
    rp.atmosphere = rendererProfileInit();
    rp.clouds = rendererProfileInit();
    rp.weather = rendererProfileInit();
    rp.water = rendererProfileInit();
    rp.composite = rendererProfileInit();
    rp.bloom = rendererProfileInit();
    rp.tonemap = rendererProfileInit();
    rp.final = rendererProfileInit();
    rp.totalCost = 0.0;
    rp.totalBandwidth = 0.0;
    rp.totalVRAM = 0.0;
    return rp;
}

// Accumulate pass cost
void rendererProfileAccumulate(inout PassProfile pass, float fetches, float rays, float steps, float history) {
    pass.textureFetches += fetches;
    pass.rayCount += rays;
    pass.raymarchSteps += steps;
    pass.temporalHistoryUsage += history;
    pass.gpuCost += fetches * 0.1 + rays * 0.5 + steps * 0.3 + history * -0.2;
}

// Get pass profile by node type
PassProfile rendererGetPassProfile(RendererProfile rp, float nodeType) {
    PassProfile p = rendererProfileInit();
    if (nodeType == RENDER_NODE_GEOMETRY) return rp.geometry;
    if (nodeType == RENDER_NODE_GBUFFER) return rp.gbuffer;
    if (nodeType == RENDER_NODE_SHADOW) return rp.shadow;
    if (nodeType == RENDER_NODE_LIGHTING) return rp.lighting;
    if (nodeType == RENDER_NODE_DEFERRED) return rp.deferred;
    if (nodeType == RENDER_NODE_SSAO) return rp.ssao;
    if (nodeType == RENDER_NODE_SSR) return rp.ssr;
    if (nodeType == RENDER_NODE_SSGI) return rp.ssgi;
    if (nodeType == RENDER_NODE_ATMOSPHERE) return rp.atmosphere;
    if (nodeType == RENDER_NODE_CLOUDS) return rp.clouds;
    if (nodeType == RENDER_NODE_WEATHER) return rp.weather;
    if (nodeType == RENDER_NODE_WATER) return rp.water;
    if (nodeType == RENDER_NODE_COMPOSITE) return rp.composite;
    if (nodeType == RENDER_NODE_BLOOM) return rp.bloom;
    if (nodeType == RENDER_NODE_TONEMAP) return rp.tonemap;
    if (nodeType == RENDER_NODE_FINAL) return rp.final;
    return p;
}

#endif
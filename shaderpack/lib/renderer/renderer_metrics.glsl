#version 150
#ifndef RENDERER_METRICS_GLSL
#define RENDERER_METRICS_GLSL

#include "renderer_common.glsl"
#include "renderer_profiler.glsl"
#include "renderer_budget.glsl"

// Unified metrics collection for renderer-wide analysis

struct RendererMetrics {
    float frameTime;
    float gpuTime;
    float cpuTime;
    float drawCalls;
    float triangleCount;
    float textureBinds;
    float samplerBinds;
    float shaderSwitches;
    float fps;
    float frameNumber;
    PassProfile passes[16];
    float passCount;
    GPUBudget budget;
    MemoryStats memory;
};

// Initialize metrics
RendererMetrics rendererMetricsInit(float quality) {
    RendererMetrics m;
    m.frameTime = 0.0;
    m.gpuTime = 0.0;
    m.cpuTime = 0.0;
    m.drawCalls = 0.0;
    m.triangleCount = 0.0;
    m.textureBinds = 0.0;
    m.samplerBinds = 0.0;
    m.shaderSwitches = 0.0;
    m.fps = 60.0;
    m.frameNumber = 0.0;
    m.passCount = 16.0;
    m.budget = rendererBudgetInit(quality);
    m.memory = rendererMemoryStats(rendererDefaultGraph());
    return m;
}

// Update frame metrics
void rendererMetricsUpdateFrame(inout RendererMetrics m, float frameTime, float gpuTime) {
    m.frameTime = frameTime;
    m.gpuTime = gpuTime;
    m.fps = 1.0 / max(frameTime, 0.001);
    m.frameNumber += 1.0;
}

// Record pass execution
void rendererMetricsRecordPass(inout RendererMetrics m, float nodeType, PassProfile profile) {
    for (int i = 0; i < 16; i++) {
        if (float(i) == nodeType) {
            m.passes[i] = profile;
            break;
        }
    }
}

// Get total texture binds
float rendererMetricsTotalTextureBinds(RendererMetrics m) {
    return m.textureBinds;
}

// Get total sampler binds
float rendererMetricsTotalSamplerBinds(RendererMetrics m) {
    return m.samplerBinds;
}

// Get bottleneck category
float rendererMetricsBottleneck(RendererMetrics m) {
    float maxCost = 0.0;
    float bottleneck = 0.0;
    for (int i = 0; i < 16; i++) {
        if (m.passes[i].gpuCost > maxCost) {
            maxCost = m.passes[i].gpuCost;
            bottleneck = float(i);
        }
    }
    return bottleneck;
}

#endif
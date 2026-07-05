#version 150
#ifndef RENDERER_MEMORY_GLSL
#define RENDERER_MEMORY_GLSL

#include "renderer_common.glsl"

// Memory analysis and tracking for renderer-wide optimization

struct MemoryAnalysis {
    float peakUsage;
    float currentUsage;
    float tempAllocations;
    float historyPoolUsage;
    float aliasedResources;
    float unusedResources;
    float lifetimeOverlap;
    float memoryEfficiency;
    float estimatedBandwidth;
    float estimatedVRAM;
};

// Initialize memory analysis
MemoryAnalysis rendererMemoryAnalysisInit() {
    MemoryAnalysis m;
    m.peakUsage = 0.0;
    m.currentUsage = 0.0;
    m.tempAllocations = 0.0;
    m.historyPoolUsage = 0.0;
    m.aliasedResources = 0.0;
    m.unusedResources = 0.0;
    m.lifetimeOverlap = 0.0;
    m.memoryEfficiency = 1.0;
    m.estimatedBandwidth = 0.0;
    m.estimatedVRAM = 0.0;
    return m;
}

// Update memory analysis from render graph
void rendererMemoryAnalysisUpdate(inout MemoryAnalysis m, RenderGraph g) {
    m.currentUsage = 0.0;
    m.tempAllocations = g.tempAllocations;
    m.historyPoolUsage = g.historyPoolSize;
    m.aliasedResources = 0.0;
    m.unusedResources = 0.0;

    for (int i = 0; i < 32; i++) {
        if (float(i) >= g.resourceCount) break;
        float resourceSize = g.resources[i].width * g.resources[i].height * 4.0;
        m.currentUsage += resourceSize;

        if (g.resources[i].aliased) m.aliasedResources += 1.0;
        if (g.resources[i].temporary) m.tempAllocations += resourceSize;
    }

    m.peakUsage = max(m.peakUsage, m.currentUsage);
    m.memoryEfficiency = m.peakUsage > 0.0 ? m.currentUsage / m.peakUsage : 1.0;
}

// Estimate bandwidth for a resource
float rendererMemoryEstimateBandwidth(float width, float height, float accesses) {
    float pixels = width * height;
    float bytesPerPixel = 4.0;
    return pixels * bytesPerPixel * accesses;
}

// Get memory efficiency
float rendererMemoryEfficiency(MemoryAnalysis m) {
    return m.memoryEfficiency;
}

// Check for memory leaks
bool rendererMemoryHasLeaks(MemoryAnalysis m) {
    return m.tempAllocations > 0.0 && m.currentUsage > m.peakUsage * 1.5;
}

#endif
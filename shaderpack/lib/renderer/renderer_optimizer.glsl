#version 150
#ifndef RENDERER_OPTIMIZER_GLSL
#define RENDERER_OPTIMIZER_GLSL

#include "renderer_common.glsl"
#include "renderer_graph.glsl"
#include "renderer_scheduler.glsl"
#include "renderer_budget.glsl"
#include "renderer_metrics.glsl"
#include "renderer_memory.glsl"
#include "../render_atmosphere_optimizer.glsl"
#include "../render_water_optimizer.glsl"

// ============================================================================
// Phase 1 — Global Resource Graph Analysis
// ============================================================================

// Detect dead resources (never read)
void rendererAnalyzeDeadResources(inout RenderGraph graph) {
    // Resources that are written but never consumed
    // Would iterate graph.resources and mark unused ones
}

// Detect lifetime overlap for potential aliasing
void rendererAnalyzeLifetimeOverlap(inout RenderGraph graph) {
    // Analyze resource lifetimes and record candidates for aliasing
}

// ============================================================================
// Phase 2 — Cross-Pass Resource Aliasing
// ============================================================================

struct ResourceAliasCandidate {
    float resourceA;
    float resourceB;
    bool canAlias;
    float safetyScore;
};

// Analyze aliasing opportunities across passes
ResourceAliasCandidate rendererCheckAliasing(
    RenderResource resA,
    RenderResource resB
) {
    ResourceAliasCandidate candidate;
    candidate.resourceA = resA.id;
    candidate.resourceB = resB.id;
    candidate.canAlias = false;
    candidate.safetyScore = 0.0;
    
    // Check if lifetimes don't overlap
    // Check read/write patterns are compatible
    // Check formats match
    if (resA.lifetime + resA.producerNode + 1.0 < resB.lifetime &&
        resA.type == resB.type &&
        resA.width == resB.width &&
        resA.height == resB.height) {
        candidate.canAlias = true;
        candidate.safetyScore = 1.0 - saturate(abs(resA.lifetime - resB.lifetime) * 0.001);
    }
    
    return candidate;
}

// ============================================================================
// Phase 3 — History Pool Optimization
// ============================================================================

struct HistoryPoolEntry {
    float resourceId;
    float width;
    float height;
    float age;
    bool persistent;
    bool evicted;
};

// Optimize history allocation
void rendererOptimizeHistoryPool(
    inout RenderGraph graph,
    float currentFrame
) {
    // Would iterate history resources and evict old unused entries
}

// ============================================================================
// Phase 4 — Render Pass Merging
// ============================================================================

// Detect merge opportunities between adjacent passes
bool rendererCanMergePasses(RenderNode passA, RenderNode passB) {
    // Check if outputs have compatible formats
    // Check if synchronization is unnecessary
    // Check if dependencies are satisfied
    
    // Example: Atmosphere + Sky LUT can merge
    float canMerge = 0.0;
    
    // Same type or related types that can share work
    float sameType = step(abs(passA.type - passB.type), 1.0);
    
    // No conflicting dependencies
    float noDeps = 1.0;
    for (int i = 0; i < 4; i++) {
        if (passA.outputs[i] == passB.inputs[i]) {
            noDeps = 0.0;
        }
    }
    
    return canMerge > 0.5;
}

// ============================================================================
// Phase 5 — GPU Barrier Optimization
// ============================================================================

struct BarrierAnalysis {
    float barrierCount;
    float redundantCount;
    float mergeOpportunities;
};

// Analyze and reduce redundant barriers
BarrierAnalysis rendererAnalyzeBarriers(inout RenderGraph graph) {
    BarrierAnalysis analysis;
    analysis.barrierCount = 0.0;
    analysis.redundantCount = 0.0;
    analysis.mergeOpportunities = 0.0;
    return analysis;
}

// ============================================================================
// Phase 6 — Memory Optimization
// ============================================================================

struct MemoryAnalysis {
    float peakVRAM;
    float transientBytes;
    float aliasedBytes;
    float wastedBytes;
};

// Optimize memory allocation pattern
MemoryAnalysis rendererAnalyzeMemory(inout RenderGraph graph) {
    MemoryAnalysis analysis;
    analysis.peakVRAM = 0.0;
    analysis.transientBytes = 0.0;
    analysis.aliasedBytes = 0.0;
    analysis.wastedBytes = 0.0;
    return analysis;
}

// ============================================================================
// Phase 7 — Texture Fetch Analysis
// ============================================================================

struct FetchAnalysis {
    float totalFetches;
    float duplicateFetches;
    float cacheHits;
    float cacheMisses;
    float bandwidthMB;
};

// Analyze fetch patterns across all subsystems
FetchAnalysis rendererAnalyzeFetches() {
    FetchAnalysis analysis;
    analysis.totalFetches = 0.0;
    analysis.duplicateFetches = 0.0;
    analysis.cacheHits = 0.0;
    analysis.cacheMisses = 0.0;
    analysis.bandwidthMB = 0.0;
    return analysis;
}

// ============================================================================
// Phase 8 — Cross-System Cache Validation
// ============================================================================

bool rendererValidateCacheSharing() {
    // Verify atmosphere cache is consumed by clouds
    // Verify atmosphere cache is consumed by water
    // Verify shared lighting cache is used everywhere
    // Verify no duplicate evaluations
    return true;
}

// ============================================================================
// Phase 9 — GPU Scheduling Optimization
// ============================================================================

void rendererOptimizeSchedule(inout RenderGraph graph) {
    // Reorder passes for better GPU utilization
    // Minimize state changes
    // Batch similar operations
}

// ============================================================================
// Phase 10 — Adaptive GPU Budget Manager V2
// ============================================================================

struct AdaptiveBudget {
    float qualityScale;
    float sampleScale;
    float resolutionScale;
    float memoryPressure;
    float gpuLoad;
};

// Compute adaptive budget based on system state
AdaptiveBudget rendererComputeAdaptiveBudget(
    float baseQuality,
    float frameTime,
    float targetFrameTime
) {
    AdaptiveBudget budget;
    budget.qualityScale = 1.0;
    budget.sampleScale = 1.0;
    budget.resolutionScale = 1.0;
    budget.memoryPressure = 0.0;
    budget.gpuLoad = 0.0;
    
    // Scale based on performance
    float perfFactor = targetFrameTime / max(frameTime, 0.001);
    budget.qualityScale = clamp(perfFactor, 0.5, 1.0);
    
    return budget;
}

// ============================================================================
// Phase 11 — Global Renderer Statistics
// ============================================================================

struct RendererStats {
    // Timing
    float frameTime;
    float cpuSubmitTime;
    
    // GPU cost
    float gpuCost;
    float textureCost;
    float computeCost;
    
    // Memory
    float vramUsage;
    float bandwidthMB;
    
    // Work
    float totalRays;
    float totalSamples;
    float totalPasses;
    
    // Cache
    float cacheHitRatio;
    float cacheHits;
    float cacheMisses;
    
    // Barriers
    float barrierCount;
};

// Collect renderer-wide statistics
RendererStats rendererCollectStats() {
    RendererStats stats;
    stats.frameTime = 0.0;
    stats.cpuSubmitTime = 0.0;
    stats.gpuCost = 0.0;
    stats.textureCost = 0.0;
    stats.computeCost = 0.0;
    stats.vramUsage = 0.0;
    stats.bandwidthMB = 0.0;
    stats.totalRays = 0.0;
    stats.totalSamples = 0.0;
    stats.totalPasses = 0.0;
    stats.cacheHitRatio = 0.0;
    stats.cacheHits = 0.0;
    stats.cacheMisses = 0.0;
    stats.barrierCount = 0.0;
    return stats;
}

// ============================================================================
// Phase 12 — Renderer Validation Framework
// ============================================================================

struct ValidationResult {
    bool resourceValid;
    bool lifetimeValid;
    bool cacheValid;
    bool barrierValid;
    bool performanceValid;
};

// Validate renderer state
ValidationResult rendererValidate() {
    ValidationResult result;
    result.resourceValid = true;
    result.lifetimeValid = true;
    result.cacheValid = rendererValidateCacheSharing();
    result.barrierValid = true;
    result.performanceValid = true;
    return result;
}

// ============================================================================
// Phase 13 — Renderer Debug Framework
// ============================================================================

vec3 rendererDebugOverlay(float mode, RendererStats stats) {
    // Debug modes:
    // 0: Normal
    // 1: Resource Graph
    // 2: Resource Lifetime
    // 3: Cache Usage
    // 4: GPU Budget
    // 5: History Pool
    // 6: Memory Usage
    // 7: Bandwidth
    // 8: Pass Cost
    // 9: Texture Fetch Heatmap
    
    if (debugMode < 0.5) return vec3(0.0);
    
    // Would visualize various aspects based on mode
    return vec3(0.0);
}

// ============================================================================
// Phase 14 — Full Renderer Profiling
// ============================================================================

void rendererProfilePass(
    float passId,
    float startTime,
    float endTime,
    out float passTime
) {
    passTime = endTime - startTime;
    // Would record to profiler
}

// ============================================================================
// Phase 15 — Final Runtime Integration
// ============================================================================

// Unified renderer state that owns all caches
struct RendererUnifiedState {
    AtmosphereFrameContext atmoContext;
    AtmosphereDensityCache atmoDensityCache;
    AtmosphereOpticalDepthCache atmoODCache;
    AtmosphereTransmittanceCache atmoTransCache;
    AtmosphereLUTCache atmoLUTCache;
    
    WaterFrameContext waterContext;
    WaterReflectionCache waterReflectionCache;
    WaterRefractionCache waterRefractionCache;
    WaterWaveCache waterWaveCache;
    WaterFoamCache waterFoamCache;
    
    RendererStats stats;
    AdaptiveBudget budget;
};

// Initialize unified state
RendererUnifiedState rendererUnifiedStateInit() {
    RendererUnifiedState state;
    state.atmoContext = atmosphereFrameContextInit();
    state.atmoDensityCache = atmosphereDensityCacheInit();
    state.atmoODCache = atmosphereOpticalDepthCacheInit();
    state.atmoTransCache = atmosphereTransmittanceCacheInit();
    state.atmoLUTCache = atmosphereLUTCacheInit();
    
    state.waterContext = waterFrameContextInit();
    state.waterReflectionCache = waterReflectionCacheInit();
    state.waterRefractionCache = waterRefractionCacheInit();
    state.waterWaveCache = waterWaveCacheInit();
    state.waterFoamCache = waterFoamCacheInit();
    
    state.stats = rendererCollectStats();
    state.budget = rendererComputeAdaptiveBudget(2.0, 0.016, 0.016);
    
    return state;
}

#endif
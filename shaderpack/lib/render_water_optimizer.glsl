#version 150
#ifndef RENDER_WATER_OPTIMIZER_GLSL
#define RENDER_WATER_OPTIMIZER_GLSL

#include "renderer_common.glsl"
#include "renderer_sampling.glsl"
#include "renderer_budget.glsl"
#include "renderer_metrics.glsl"
#include "renderer_profiler.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../atmosphere/atmosphere_lighting.glsl"
#include "../water/water_common.glsl"
#include "../water/water_surface.glsl"
#include "../water/water_waves.glsl"

// ============================================================================
// Phase 1 — Water Frame Context
// ============================================================================

struct WaterFrameContext {
    // Position data
    vec3 worldPosition;
    vec3 viewPosition;
    vec3 surfaceNormal;
    vec3 viewDirection;
    
    // Ray directions
    vec3 reflectionDirection;
    vec3 refractionDirection;
    
    // Water properties
    float waterDepth;
    float waveHeight;
    float waterThickness;
    bool isUnderwater;
    
    // Weather/Atmosphere
    float weatherIntensity;
    float cameraAltitude;
    
    // Quality
    float quality;
    float frameIndex;
    
    bool isValid;
};

// Initialize water frame context
WaterFrameContext waterFrameContextInit() {
    WaterFrameContext ctx;
    ctx.worldPosition = vec3(0.0);
    ctx.viewPosition = vec3(0.0);
    ctx.surfaceNormal = vec3(0.0, 1.0, 0.0);
    ctx.viewDirection = vec3(0.0, 0.0, 1.0);
    ctx.reflectionDirection = vec3(0.0, 0.0, 1.0);
    ctx.refractionDirection = vec3(0.0, 0.0, -1.0);
    ctx.waterDepth = 0.0;
    ctx.waveHeight = 0.0;
    ctx.waterThickness = 0.0;
    ctx.isUnderwater = false;
    ctx.weatherIntensity = 0.0;
    ctx.cameraAltitude = 0.0;
    ctx.quality = 2.0;
    ctx.frameIndex = 0.0;
    ctx.isValid = false;
    return ctx;
}

// Compute water frame context
WaterFrameContext waterComputeFrameContext(
    vec3 worldPos,
    vec3 viewDir,
    vec3 normal,
    AtmosphereRuntime r,
    float depth,
    bool underwater
) {
    WaterFrameContext ctx;
    ctx.worldPosition = worldPos;
    ctx.viewPosition = cameraPosition - worldPos;
    ctx.surfaceNormal = normal;
    ctx.viewDirection = viewDir;
    
    // Compute reflection/refraction directions
    ctx.reflectionDirection = reflect(viewDir, normal);
    ctx.refractionDirection = refract(viewDir, normal, 0.75); // Water IOR approximation
    
    ctx.waterDepth = depth;
    ctx.waveHeight = 0.0;
    ctx.waterThickness = depth;
    ctx.isUnderwater = underwater;
    ctx.weatherIntensity = r.weatherIntensity;
    ctx.cameraAltitude = r.cameraAltitude;
    ctx.quality = r.quality;
    ctx.frameIndex = frameTimeCounter;
    ctx.isValid = true;
    
    return ctx;
}

// ============================================================================
// Phase 2 — Reflection Cache
// ============================================================================

struct WaterReflectionCache {
    vec3 ssrResult;
    vec3 skyReflection;
    vec3 cloudReflection;
    float confidence;
    float roughness;
    
    vec3 lastViewDir;
    vec3 lastNormal;
    float lastRoughness;
    float frameIndex;
    
    uint64_t queryID;
    bool valid;
};

// Initialize reflection cache
WaterReflectionCache waterReflectionCacheInit() {
    WaterReflectionCache cache;
    cache.ssrResult = vec3(0.0);
    cache.skyReflection = vec3(0.0);
    cache.cloudReflection = vec3(0.0);
    cache.confidence = 1.0;
    cache.roughness = 0.0;
    cache.lastViewDir = vec3(0.0);
    cache.lastNormal = vec3(0.0, 1.0, 0.0);
    cache.lastRoughness = 0.0;
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 3 — Refraction Cache
// ============================================================================

struct WaterRefractionCache {
    vec3 refractionColor;
    float refractionDepth;
    float waterThickness;
    float underwaterFog;
    vec2 distortionOffset;
    
    vec3 lastWorldPos;
    float lastDepth;
    float frameIndex;
    
    uint64_t queryID;
    bool valid;
};

// Initialize refraction cache
WaterRefractionCache waterRefractionCacheInit() {
    WaterRefractionCache cache;
    cache.refractionColor = vec3(0.0);
    cache.refractionDepth = 0.0;
    cache.waterThickness = 0.0;
    cache.underwaterFog = 1.0;
    cache.distortionOffset = vec2(0.0);
    cache.lastWorldPos = vec3(0.0);
    cache.lastDepth = 0.0;
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 4 — Shared Lighting Cache Integration
// ============================================================================

// Consume shared atmosphere lighting
vec3 waterGetSharedAtmosphereLighting(
    AtmosphereParameters p,
    AtmosphereRuntime r,
    float height
) {
    // Reuse atmosphere ambient sky
    return atmosphereAmbientSky(p, r, height);
}

// ============================================================================
// Phase 5 — Adaptive Reflection Budget
// ============================================================================

float waterAdaptiveReflectionSamples(
    float quality,
    float roughness,
    float confidence,
    float budgetRemaining
) {
    // Base samples from quality
    float samples = atmosphereQualityScale(quality, 2.0, 4.0, 8.0, 12.0);
    
    // Roughness-based scaling (rougher = fewer samples)
    float roughFactor = 1.0 + roughness * 2.0;
    samples *= roughFactor;
    
    // Confidence scaling (low confidence = more samples)
    float confFactor = 0.5 + 0.5 * confidence;
    samples *= confFactor;
    
    // Budget-based reduction
    if (budgetRemaining < 0.3) {
        samples *= 0.5;
    } else if (budgetRemaining < 0.6) {
        samples *= 0.75;
    }
    
    return max(samples, 2.0);
}

// ============================================================================
// Phase 6 — Adaptive Refraction Budget
// ============================================================================

float waterAdaptiveRefractionSamples(
    float waterDepth,
    float distortion,
    float underwater,
    float budgetRemaining
) {
    float samples = 1.0;
    
    // Deeper water = more samples
    float depthFactor = 1.0 + saturate(waterDepth * 0.1);
    samples *= depthFactor;
    
    // Distortion increases samples
    float distortFactor = 1.0 + distortion * 2.0;
    samples *= distortFactor;
    
    // Underwater requires more samples
    float underFactor = underwater ? 1.5 : 1.0;
    samples *= underFactor;
    
    // Budget-based reduction
    if (budgetRemaining < 0.3) {
        samples *= 0.5;
    } else if (budgetRemaining < 0.6) {
        samples *= 0.75;
    }
    
    return max(samples, 1.0);
}

// ============================================================================
// Phase 7 — Wave Evaluation Cache
// ============================================================================

struct WaterWaveCache {
    float waveHeight;
    vec3 waveNormal;
    vec3 waveTangent;
    vec3 waveBinormal;
    vec3 waveDisplacement;
    
    vec2 lastUV;
    float frameIndex;
    
    bool valid;
};

// Initialize wave cache
WaterWaveCache waterWaveCacheInit() {
    WaterWaveCache cache;
    cache.waveHeight = 0.0;
    cache.waveNormal = vec3(0.0, 1.0, 0.0);
    cache.waveTangent = vec3(1.0, 0.0, 0.0);
    cache.waveBinormal = vec3(0.0, 0.0, 1.0);
    cache.waveDisplacement = vec3(0.0);
    cache.lastUV = vec2(0.0);
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 8 — Foam Cache
// ============================================================================

struct WaterFoamCache {
    float foamDensity;
    float foamCoverage;
    float shoreFoam;
    float crestFoam;
    float temporalFoam;
    
    vec2 lastUV;
    float lastWaveHeight;
    float frameIndex;
    
    bool dirty;
    bool valid;
};

// Initialize foam cache
WaterFoamCache waterFoamCacheInit() {
    WaterFoamCache cache;
    cache.foamDensity = 0.0;
    cache.foamCoverage = 0.0;
    cache.shoreFoam = 0.0;
    cache.crestFoam = 0.0;
    cache.temporalFoam = 0.0;
    cache.lastUV = vec2(0.0);
    cache.lastWaveHeight = 0.0;
    cache.frameIndex = 0.0;
    cache.dirty = true;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 9 — Caustics Optimization
// ============================================================================

float waterAdaptiveCausticsSamples(
    float waterDepth,
    float quality,
    float surfaceArea,
    float budgetRemaining
) {
    // Base samples from quality
    float samples = atmosphereQualityScale(quality, 2.0, 4.0, 6.0, 8.0);
    
    // Deeper water less caustics
    float depthFactor = exp(-waterDepth * 0.05);
    samples *= (0.5 + 0.5 * depthFactor);
    
    // Surface area scaling
    float areaFactor = 0.5 + 0.5 * surfaceArea;
    samples *= areaFactor;
    
    // Budget-based reduction
    if (budgetRemaining < 0.3) {
        samples *= 0.5;
    } else if (budgetRemaining < 0.6) {
        samples *= 0.75;
    }
    
    return max(samples, 1.0);
}

// ============================================================================
// Phase 11 — Bandwidth Optimization
// ============================================================================

vec4 waterSharedCacheLookup(
    WaterFrameContext ctx,
    out vec4 debugStats
) {
    debugStats = vec4(0.0);
    return vec4(1.0);
}

// ============================================================================
// Phase 12 — Branch Optimization
// ============================================================================

// Branchless Fresnel using Schlick approximation
float waterBranchlessFresnel(float cosTheta, float roughness) {
    float F0 = 0.02 + 0.08 * roughness;
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

// ============================================================================
// Phase 13 — GPU Statistics Integration
// ============================================================================

void waterRecordStats(
    inout RendererMetrics metrics,
    WaterReflectionCache reflectionCache,
    WaterRefractionCache refractionCache,
    WaterWaveCache waveCache,
    WaterFoamCache foamCache
) {
    // Integration with renderer_metrics would be implemented here
}

// ============================================================================
// Phase 14 — Debug Validation Layer
// ============================================================================

vec3 waterDebugOverlay(float mode, WaterFrameContext ctx) {
    // Debug modes:
    // 0: Normal
    // 1: Reflection
    // 2: Refraction
    // 3: Water Thickness
    // 4: Foam Density
    // 5: Wave Height
    // 6: Cache Stats
    
    if (debugMode < 0.5) return vec3(0.0);
    
    if (mode < 1.0) return vec3(0.0);
    if (mode < 2.0) return vec3(ctx.waterThickness * 0.1);
    if (mode < 3.0) return vec3(ctx.waveHeight * 0.5);
    
    return vec3(0.0);
}

#endif
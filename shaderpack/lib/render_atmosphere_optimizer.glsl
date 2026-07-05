#version 150
#ifndef RENDER_ATMOSPHERE_OPTIMIZER_GLSL
#define RENDER_ATMOSPHERE_OPTIMIZER_GLSL

#include "renderer_common.glsl"
#include "renderer_sampling.glsl"
#include "renderer_budget.glsl"
#include "renderer_metrics.glsl"
#include "renderer_profiler.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../atmosphere/atmosphere_density.glsl"
#include "../atmosphere/atmosphere_optical_depth.glsl"
#include "../atmosphere/atmosphere_transmittance.glsl"
#include "../atmosphere/atmosphere_multiscatter.glsl"
#include "../atmosphere/atmosphere_lut.glsl"

// ============================================================================
// Phase 1 — Atmosphere Frame Context
// ============================================================================

struct AtmosphereFrameContext {
    // Camera state
    vec3 worldPosition;
    vec3 viewDirection;
    float cameraAltitude;
    float height;
    
    // Light directions
    vec3 sunDirection;
    vec3 moonDirection;
    float sunElevation;
    float moonElevation;
    
    // Weather state
    float weatherIntensity;
    float rainStrength;
    float wetness;
    
    // Quality parameters
    float quality;
    float sampleCount;
    float lutResolution;
    
    // Cache validation
    float frameIndex;
    bool isValid;
};

// Initialize atmosphere frame context
AtmosphereFrameContext atmosphereFrameContextInit() {
    AtmosphereFrameContext ctx;
    ctx.worldPosition = vec3(0.0);
    ctx.viewDirection = vec3(0.0, 0.0, 1.0);
    ctx.cameraAltitude = 0.0;
    ctx.height = 0.0;
    ctx.sunDirection = vec3(0.0, 1.0, 0.0);
    ctx.moonDirection = vec3(0.0, -1.0, 0.0);
    ctx.sunElevation = 1.0;
    ctx.moonElevation = -1.0;
    ctx.weatherIntensity = 0.0;
    ctx.rainStrength = 0.0;
    ctx.wetness = 0.0;
    ctx.quality = 2.0;
    ctx.sampleCount = 8.0;
    ctx.lutResolution = 96.0;
    ctx.frameIndex = 0.0;
    ctx.isValid = false;
    return ctx;
}

// Compute atmosphere frame context (called once per frame/pixel)
AtmosphereFrameContext atmosphereComputeFrameContext(
    vec3 worldPos,
    vec3 viewDir,
    AtmosphereRuntime r
) {
    AtmosphereFrameContext ctx;
    ctx.worldPosition = worldPos;
    ctx.viewDirection = viewDir;
    ctx.cameraAltitude = r.cameraAltitude;
    ctx.height = max(worldPos.y - 64.0, 0.0);
    ctx.sunDirection = r.sunDirection;
    ctx.moonDirection = r.moonDirection;
    ctx.sunElevation = r.sunElevation;
    ctx.moonElevation = r.moonElevation;
    ctx.weatherIntensity = r.weatherIntensity;
    ctx.rainStrength = r.weatherIntensity;
    ctx.wetness = 0.0;
    ctx.quality = r.quality;
    ctx.sampleCount = r.sampleCount;
    ctx.lutResolution = r.lutResolution;
    ctx.frameIndex = frameTimeCounter;
    ctx.isValid = true;
    return ctx;
}

// ============================================================================
// Phase 2 — Density Cache
// ============================================================================

struct AtmosphereDensityCache {
    vec3 rayleighDensity;
    vec3 mieDensity;
    vec3 ozoneDensity;
    vec3 airDensity;
    float altitudeDensity;
    
    vec3 lastWorldPos;
    float lastCameraAlt;
    float lastWeather;
    float frameIndex;
    
    uint64_t queryID;
    bool valid;
};

// Initialize density cache
AtmosphereDensityCache atmosphereDensityCacheInit() {
    AtmosphereDensityCache cache;
    cache.rayleighDensity = vec3(1.0);
    cache.mieDensity = vec3(1.0);
    cache.ozoneDensity = vec3(1.0);
    cache.airDensity = vec3(1.0);
    cache.altitudeDensity = 1.0;
    cache.lastWorldPos = vec3(0.0);
    cache.lastCameraAlt = 0.0;
    cache.lastWeather = 0.0;
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// Get cached densities with validation
vec4 atmosphereGetCachedDensities(
    inout AtmosphereDensityCache cache,
    float height,
    AtmosphereRuntime r,
    out vec4 debugStats
) {
    debugStats = vec4(0.0);
    
    // Check cache validity
    float altDelta = abs(cache.lastCameraAlt - r.cameraAltitude);
    float weatherDelta = abs(cache.lastWeather - r.weatherIntensity);
    bool cacheValid = cache.valid && altDelta < 1.0 && weatherDelta < 0.05;
    
    if (cacheValid) {
        debugStats = vec4(1.0, 0.0, 0.0, 1.0); // Cache hit
        return vec4(cache.rayleighDensity.x, cache.mieDensity.x, cache.ozoneDensity.x, cache.altitudeDensity);
    }
    
    // Compute densities
    vec3 scaleHeights = vec3(ATMOSPHERE_RAYLEIGH_SCALE, ATMOSPHERE_MIE_SCALE, ATMOSPHERE_OZONE_SCALE);
    vec3 densities = atmosphereCombinedDensity(
        height, scaleHeights,
        r.cameraAltitude, r.fogAltitude, r.waterLevel, r.mountainHeight, r.weatherIntensity
    );
    
    cache.rayleighDensity = vec3(densities.x);
    cache.mieDensity = vec3(densities.y);
    cache.ozoneDensity = vec3(densities.z);
    cache.airDensity = densities;
    cache.altitudeDensity = atmosphereDensityHeight(height, ATMOSPHERE_RAYLEIGH_SCALE);
    cache.lastWorldPos = vec3(0.0); // Would be worldPos in real implementation
    cache.lastCameraAlt = r.cameraAltitude;
    cache.lastWeather = r.weatherIntensity;
    cache.valid = true;
    
    debugStats = vec4(0.0, 1.0, 0.0, 1.0); // Cache miss
    return vec4(densities.x, densities.y, densities.z, cache.altitudeDensity);
}

// ============================================================================
// Phase 3 — Optical Depth Cache
// ============================================================================

struct AtmosphereOpticalDepthCache {
    vec3 viewOpticalDepth;
    vec3 sunOpticalDepth;
    vec3 moonOpticalDepth;
    float atmosphericThickness;
    
    vec3 lastViewDir;
    vec3 lastSunDir;
    vec3 lastMoonDir;
    float frameIndex;
    
    uint64_t queryID;
    bool valid;
};

// Initialize optical depth cache
AtmosphereOpticalDepthCache atmosphereOpticalDepthCacheInit() {
    AtmosphereOpticalDepthCache cache;
    cache.viewOpticalDepth = vec3(0.0);
    cache.sunOpticalDepth = vec3(0.0);
    cache.moonOpticalDepth = vec3(0.0);
    cache.atmosphericThickness = 0.0;
    cache.lastViewDir = vec3(0.0);
    cache.lastSunDir = vec3(0.0);
    cache.lastMoonDir = vec3(0.0);
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 4 — Transmittance Cache
// ============================================================================

struct AtmosphereTransmittanceCache {
    vec3 sunTransmittance;
    vec3 moonTransmittance;
    vec3 viewTransmittance;
    vec3 horizonTransmittance;
    
    vec3 lastViewDir;
    vec3 lastSunDir;
    float lastHeight;
    float frameIndex;
    
    uint64_t queryID;
    bool valid;
};

// Initialize transmittance cache
AtmosphereTransmittanceCache atmosphereTransmittanceCacheInit() {
    AtmosphereTransmittanceCache cache;
    cache.sunTransmittance = vec3(1.0);
    cache.moonTransmittance = vec3(1.0);
    cache.viewTransmittance = vec3(1.0);
    cache.horizonTransmittance = vec3(1.0);
    cache.lastViewDir = vec3(0.0);
    cache.lastSunDir = vec3(0.0);
    cache.lastHeight = 0.0;
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 5 — Sky LUT Optimization
// ============================================================================

struct AtmosphereLUTCache {
    vec3 skyRadiance;
    vec2 lutCoords;
    float resolution;
    float quality;
    float frameIndex;
    bool dirty;
    bool valid;
};

// Initialize LUT cache
AtmosphereLUTCache atmosphereLUTCacheInit() {
    AtmosphereLUTCache cache;
    cache.skyRadiance = vec3(0.0);
    cache.lutCoords = vec2(0.5);
    cache.resolution = 96.0;
    cache.quality = 2.0;
    cache.frameIndex = 0.0;
    cache.dirty = true;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 6 — Adaptive Scattering Budget
// ============================================================================

float atmosphereAdaptiveScatteringBudget(
    AtmosphereRuntime r,
    float budgetRemaining,
    float densityMean,
    float temporalConfidence
) {
    float baseBudget = 1.0;
    
    // Reduce when high altitude (thin atmosphere)
    float altitudeFactor = saturate(r.cameraAltitude * 0.001);
    baseBudget *= (0.5 + 0.5 * altitudeFactor);
    
    // Reduce when clear weather
    float weatherFactor = 1.0 - r.weatherIntensity * 0.3;
    baseBudget *= weatherFactor;
    
    // Reduce when sun is low (less scattering)
    float sunFactor = saturate(r.sunElevation * 2.0);
    baseBudget *= (0.6 + 0.4 * sunFactor);
    
    // Temporal stability bonus
    baseBudget *= (0.8 + 0.2 * temporalConfidence);
    
    // Budget constraint
    baseBudget *= clamp(budgetRemaining, 0.3, 1.0);
    
    return baseBudget;
}

// ============================================================================
// Phase 7 — Adaptive Multiple Scattering
// ============================================================================

float atmosphereAdaptiveMultiScatterIterations(
    AtmosphereRuntime r,
    float densityMean
) {
    // Quality base
    float iterations = atmosphereQualityScale(r.quality, 1.0, 2.0, 3.0, 4.0);
    
    // Reduce for thin atmosphere
    float altitudeFactor = exp(-r.cameraAltitude * 0.0001);
    iterations *= (0.5 + 0.5 * altitudeFactor);
    
    // Reduce for clear weather
    float weatherFactor = 1.0 + r.weatherIntensity * 0.5;
    iterations *= weatherFactor;
    
    // Reduce for low sun elevation
    float sunFactor = saturate(r.sunElevation * 1.5);
    iterations *= (0.6 + 0.4 * sunFactor);
    
    return max(iterations, 0.5);
}

// ============================================================================
// Phase 8 — Shared Lighting Cache
// ============================================================================

struct AtmosphereLightingCache {
    vec3 sunRadiance;
    vec3 moonRadiance;
    vec3 ambientSky;
    vec3 horizonLighting;
    vec3 groundBounce;
    
    float frameIndex;
    bool valid;
};

// Initialize lighting cache
AtmosphereLightingCache atmosphereLightingCacheInit() {
    AtmosphereLightingCache cache;
    cache.sunRadiance = vec3(0.0);
    cache.moonRadiance = vec3(0.0);
    cache.ambientSky = vec3(0.0);
    cache.horizonLighting = vec3(0.0);
    cache.groundBounce = vec3(0.0);
    cache.frameIndex = 0.0;
    cache.valid = false;
    return cache;
}

// ============================================================================
// Phase 9 — Adaptive Sampling
// ============================================================================

float atmosphereAdaptiveSampleCount(
    float quality,
    float viewZenith,
    float densityMean,
    float budgetRemaining
) {
    // Base samples from quality
    float samples = atmosphereQualityScale(quality, 8.0, 12.0, 16.0, 24.0);
    
    // Zenith-based scaling (more at horizon)
    float zenithFactor = 0.5 + 0.5 * viewZenith;
    samples *= zenithFactor;
    
    // Density-based scaling
    float densityFactor = 0.7 + 0.3 * densityMean;
    samples *= densityFactor;
    
    // Budget-based reduction
    if (budgetRemaining < 0.3) {
        samples *= 0.5;
    } else if (budgetRemaining < 0.6) {
        samples *= 0.75;
    }
    
    // Ensure minimum samples
    return max(samples, 4.0);
}

// ============================================================================
// Phase 11 — Bandwidth Optimization
// ============================================================================

// Shared cache for avoiding duplicate evaluations
vec4 atmosphereSharedCacheLookup(
    AtmosphereRuntime r,
    float height,
    float cosTheta
) {
    // Pack multiple values into single vec4 for cache efficiency
    // x = rayleigh, y = mie, z = ozone, w = transmittance
    return vec4(1.0); // Placeholder - full implementation would integrate caches
}

// ============================================================================
// Phase 12 — Branch Optimization
// ============================================================================

// Arithmetic-based conditionals (avoid branching)
float atmosphereBranchlessTwilight(float elevation) {
    // Use smoothstep instead of if/else chains
    float astro = smoothstep(-0.31, -0.21, elevation);
    float nautical = smoothstep(-0.21, -0.105, elevation);
    float civil = smoothstep(-0.105, 0.0, elevation);
    float day = smoothstep(0.0, 0.05, elevation);
    
    return mix(mix(mix(astro, nautical, 0.5), civil, 0.5), day, 0.5);
}

// ============================================================================
// Phase 13 — GPU Statistics Integration
// ============================================================================

void atmosphereRecordStats(
    inout RendererMetrics metrics,
    AtmosphereDensityCache densityCache,
    AtmosphereOpticalDepthCache odCache,
    AtmosphereTransmittanceCache transCache
) {
    // Would integrate with renderer_metrics for performance tracking
    // These would be updated in actual implementation
}

// ============================================================================
// Phase 14 — Debug Validation Layer
// ============================================================================

vec3 atmosphereDebugOverlay(float mode, AtmosphereRuntime r) {
    // Debug mode values would be displayed here
    // Compile out in production
    if (debugMode < 0.5) return vec3(0.0);
    return vec3(0.0);
}

#endif
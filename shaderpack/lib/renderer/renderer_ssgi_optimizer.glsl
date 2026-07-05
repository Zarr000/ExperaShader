#version 150
#ifndef RENDERER_SSGI_OPTIMIZER_GLSL
#define RENDERER_SSGI_OPTIMIZER_GLSL

#include "renderer_common.glsl"
#include "renderer_profiler.glsl"
#include "renderer_budget.glsl"
#include "renderer_sampling.glsl"
#include "renderer_quality.glsl"

// SSGI-specific optimization state

struct SSGIOptimizationState {
    float adaptiveRayCount;
    float adaptiveStepCount;
    float adaptiveSearchIterations;
    float rayLengthScale;
    float roughnessThreshold;
    float confidenceThreshold;
    float historyWeight;
    float fetchCount;
    float rayCount;
    float stepCount;
    float estimatedCost;
};

SSGIOptimizationState rendererSSGIOptimizerInit(float quality) {
    SSGIOptimizationState s;
    s.adaptiveRayCount = rendererQualityScale(quality, 2.0, 6.0, 10.0, 16.0, 24.0);
    s.adaptiveStepCount = rendererQualityScale(quality, 4.0, 8.0, 12.0, 16.0, 24.0);
    s.adaptiveSearchIterations = rendererQualityScale(quality, 2.0, 4.0, 6.0, 8.0, 12.0);
    s.rayLengthScale = rendererQualityScale(quality, 0.6, 0.8, 0.9, 1.0, 1.0);
    s.roughnessThreshold = 0.65;
    s.confidenceThreshold = 0.3;
    s.historyWeight = rendererQualityScale(quality, 0.6, 0.75, 0.85, 0.9, 0.95);
    s.fetchCount = 0.0;
    s.rayCount = 0.0;
    s.stepCount = 0.0;
    s.estimatedCost = 0.0;
    return s;
}

float rendererSSGIAdaptiveRayCount(float roughness, float variance, SSGIOptimizationState s) {
    float base = s.adaptiveRayCount;
    float roughReduce = base * (1.0 - roughness * 0.7);
    float varReduce = base * (1.0 - variance * 0.5);
    return max(floor(min(roughReduce, varReduce)), 1.0);
}

float rendererSSGIAdaptiveSteps(float depthComplexity, SSGIOptimizationState s) {
    float base = s.adaptiveStepCount;
    float complexReduce = base * (1.0 - depthComplexity * 0.3);
    return max(floor(complexReduce), 2.0);
}

bool rendererSSGIShouldSkip(float roughness, float confidence, SSGIOptimizationState s) {
    return roughness > s.roughnessThreshold && confidence < s.confidenceThreshold;
}

void rendererSSGIAccumulateCost(inout SSGIOptimizationState s, float fetches, float rays, float steps) {
    s.fetchCount += fetches;
    s.rayCount += rays;
    s.stepCount += steps;
    s.estimatedCost += fetches * 0.15 + rays * 0.4 + steps * 0.25;
}

#endif
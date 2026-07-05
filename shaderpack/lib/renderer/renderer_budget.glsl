#version 150
#ifndef RENDERER_BUDGET_GLSL
#define RENDERER_BUDGET_GLSL

#include "renderer_common.glsl"
#include "renderer_profiler.glsl"

// GPU Budget management for renderer-wide workload distribution

struct BudgetCategory {
    float allocated;
    float used;
    float remaining;
    float priority;
    bool flexible;
};

struct GPUBudget {
    BudgetCategory lighting;
    BudgetCategory reflection;
    BudgetCategory volumetric;
    BudgetCategory shadow;
    BudgetCategory post;
    BudgetCategory memory;
    BudgetCategory history;
    float totalBudget;
    float totalUsed;
    float efficiency;
};

// Initialize budget category
BudgetCategory rendererBudgetCategoryInit(float allocated, float priority, bool flexible) {
    BudgetCategory b;
    b.allocated = allocated;
    b.used = 0.0;
    b.remaining = allocated;
    b.priority = priority;
    b.flexible = flexible;
    return b;
}

// Initialize GPU budget
GPUBudget rendererBudgetInit(float quality) {
    GPUBudget b;
    float q = quality;

    // Budget scales with quality preset
    float lightingBudget = 100.0 * q;
    float reflectionBudget = 80.0 * q;
    float volumetricBudget = 120.0 * q;
    float shadowBudget = 60.0 * q;
    float postBudget = 40.0 * q;
    float memoryBudget = 200.0 * q;
    float historyBudget = 30.0 * q;

    b.lighting = rendererBudgetCategoryInit(lightingBudget, 1.0, false);
    b.reflection = rendererBudgetCategoryInit(reflectionBudget, 2.0, true);
    b.volumetric = rendererBudgetCategoryInit(volumetricBudget, 3.0, true);
    b.shadow = rendererBudgetCategoryInit(shadowBudget, 1.0, false);
    b.post = rendererBudgetCategoryInit(postBudget, 2.0, true);
    b.memory = rendererBudgetCategoryInit(memoryBudget, 1.0, false);
    b.history = rendererBudgetCategoryInit(historyBudget, 3.0, true);
    b.totalBudget = lightingBudget + reflectionBudget + volumetricBudget + shadowBudget + postBudget;
    b.totalUsed = 0.0;
    b.efficiency = 1.0;
    return b;
}

// Consume budget
bool rendererBudgetConsume(inout GPUBudget b, inout BudgetCategory category, float cost) {
    if (category.remaining >= cost) {
        category.used += cost;
        category.remaining -= cost;
        b.totalUsed += cost;
        return true;
    }
    return false;
}

// Redistribute budget from flexible categories
void rendererBudgetRedistribute(inout GPUBudget b) {
    float totalFlexible = 0.0;
    float totalFlexibleRemaining = 0.0;

    // Sum flexible categories
    totalFlexible += b.reflection.allocated;
    totalFlexible += b.volumetric.allocated;
    totalFlexible += b.post.allocated;
    totalFlexible += b.history.allocated;

    totalFlexibleRemaining += b.reflection.remaining;
    totalFlexibleRemaining += b.volumetric.remaining;
    totalFlexibleRemaining += b.post.remaining;
    totalFlexibleRemaining += b.history.remaining;

    // Redistribute proportionally by priority
    if (totalFlexible > 0.0 && totalFlexibleRemaining > 0.0) {
        float redistributionFactor = totalFlexibleRemaining / totalFlexible;
        b.reflection.allocated *= redistributionFactor;
        b.volumetric.allocated *= redistributionFactor;
        b.post.allocated *= redistributionFactor;
        b.history.allocated *= redistributionFactor;
    }
}

// Get budget efficiency
float rendererBudgetEfficiency(GPUBudget b) {
    if (b.totalBudget > 0.0) {
        return b.totalUsed / b.totalBudget;
    }
    return 0.0;
}

#endif
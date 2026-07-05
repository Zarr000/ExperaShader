#version 150
#ifndef RENDERER_UTIL_GLSL
#define RENDERER_UTIL_GLSL

#include "renderer_common.glsl"
#include "renderer_frame.glsl"
#include "renderer_graph.glsl"
#include "renderer_resource.glsl"
#include "renderer_scheduler.glsl"
#include "renderer_temporal.glsl"
#include "renderer_quality.glsl"
#include "renderer_validation.glsl"

// Unified renderer utility
// Single entry point for renderer core initialization and management

// Complete renderer state
struct RendererState {
    RenderGraph graph;
    FrameState frame;
    TemporalState temporal;
    ValidationResult validation;
    float quality;
    float time;
};

// Initialize renderer core
RendererState rendererInit(float time, float deltaTime, float frameNumber) {
    RendererState r;
    r.time = time;
    r.quality = clamp(cloudsQuality, 0.0, 4.0);

    // Initialize frame state
    r.frame = rendererFrameInit(frameNumber, time, deltaTime);

    // Build render graph
    r.graph = rendererBuildDefaultGraph();

    // Initialize temporal state
    r.temporal = rendererTemporalInit();

    // Register resources
    rendererRegisterStandardResources(r.graph);

    // Validate graph
    r.validation = rendererValidateGraph(r.graph);

    return r;
}

// Update renderer state
void rendererUpdate(inout RendererState r, float time, float deltaTime) {
    r.time = time;
    r.frame = rendererFrameInit(r.frame.frameNumber + 1.0, time, deltaTime);

    // Update temporal state
    rendererTemporalUpdate(r.temporal, r.frame.frameNumber, r.frame.cameraCut);

    // Reschedule graph
    rendererScheduleGraph(r.graph, r.frame);

    // Revalidate
    r.validation = rendererValidateGraph(r.graph);
}

// Check if renderer is valid
bool rendererIsValid(RendererState r) {
    return r.validation.valid;
}

// Check if temporal reset is needed
bool rendererNeedsTemporalReset(RendererState r) {
    return rendererTemporalShouldReset(r.temporal);
}

#endif
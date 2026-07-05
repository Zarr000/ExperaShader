#version 150
#ifndef RENDERER_TEMPORAL_GLSL
#define RENDERER_TEMPORAL_GLSL

#include "renderer_common.glsl"
#include "renderer_history.glsl"

// Temporal system for TAA, SSR, SSGI, Clouds, Water
// Centralizes temporal reprojection history management

struct TemporalState {
    HistoryBuffer taa;
    HistoryBuffer ssr;
    HistoryBuffer ssgi;
    HistoryBuffer cloud;
    HistoryBuffer water;
    float temporalQuality;
    bool reset;
};

// Initialize temporal state
TemporalState rendererTemporalInit() {
    TemporalState t;
    t.taa = rendererHistoryInit(RESOURCE_ID_HISTORY_TAA);
    t.ssr = rendererHistoryInit(RESOURCE_ID_HISTORY_SSR);
    t.ssgi = rendererHistoryInit(RESOURCE_ID_HISTORY_SSGI);
    t.cloud = rendererHistoryInit(RESOURCE_ID_HISTORY_CLOUD);
    t.water = rendererHistoryInit(RESOURCE_ID_HISTORY_TAA); // Reuse TAA history for water
    t.temporalQuality = 0.9;
    t.reset = true;
    return t;
}

// Update all temporal history buffers
void rendererTemporalUpdate(inout TemporalState t, float currentFrame, bool cameraCut) {
    rendererHistoryUpdate(t.taa, currentFrame, cameraCut);
    rendererHistoryUpdate(t.ssr, currentFrame, cameraCut);
    rendererHistoryUpdate(t.ssgi, currentFrame, cameraCut);
    rendererHistoryUpdate(t.cloud, currentFrame, cameraCut);
    rendererHistoryUpdate(t.water, currentFrame, cameraCut);
    t.reset = cameraCut;
}

// Check if temporal effects should reset
bool rendererTemporalShouldReset(TemporalState t) {
    return t.reset;
}

#endif
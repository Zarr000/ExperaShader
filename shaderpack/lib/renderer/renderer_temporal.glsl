#version 150
#ifndef RENDERER_TEMPORAL_GLSL
#define RENDERER_TEMPORAL_GLSL

#include "renderer_common.glsl"
#include "renderer_history.glsl"
#include "renderer_resource.glsl"

// Temporal system with resource lifetime tracking

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
    t.taa = rendererHistoryInit(RESOURCE_ID_HISTORY_TAA, 3.0, 12.0);
    t.ssr = rendererHistoryInit(RESOURCE_ID_HISTORY_SSR, 6.0, 6.0);
    t.ssgi = rendererHistoryInit(RESOURCE_ID_HISTORY_SSGI, 7.0, 7.0);
    t.cloud = rendererHistoryInit(RESOURCE_ID_HISTORY_CLOUD, 4.0, 4.0);
    t.water = rendererHistoryInit(RESOURCE_ID_HISTORY_TAA, 6.0, 12.0);
    t.temporalQuality = 0.9;
    t.reset = true;
    return t;
}

// Update all temporal history buffers
void rendererTemporalUpdate(inout TemporalState t, float currentFrame, bool cameraCut) {
    float lifetime = cameraCut ? RESOURCE_STATE_CREATED : RESOURCE_STATE_WRITTEN;
    rendererHistoryUpdate(t.taa, currentFrame, cameraCut, lifetime);
    rendererHistoryUpdate(t.ssr, currentFrame, cameraCut, lifetime);
    rendererHistoryUpdate(t.ssgi, currentFrame, cameraCut, lifetime);
    rendererHistoryUpdate(t.cloud, currentFrame, cameraCut, lifetime);
    rendererHistoryUpdate(t.water, currentFrame, cameraCut, lifetime);
    t.reset = cameraCut;
}

// Get history buffer by resource ID
HistoryBuffer rendererGetHistory(TemporalState t, float resourceId) {
    HistoryBuffer h = rendererHistoryInit(-1.0, -1.0, -1.0);
    if (resourceId == RESOURCE_ID_HISTORY_TAA) return t.taa;
    if (resourceId == RESOURCE_ID_HISTORY_SSR) return t.ssr;
    if (resourceId == RESOURCE_ID_HISTORY_SSGI) return t.ssgi;
    if (resourceId == RESOURCE_ID_HISTORY_CLOUD) return t.cloud;
    return h;
}

#endif
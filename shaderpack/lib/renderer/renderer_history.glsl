#version 150
#ifndef RENDERER_HISTORY_GLSL
#define RENDERER_HISTORY_GLSL

#include "renderer_common.glsl"

// History buffer management for temporal effects

struct HistoryBuffer {
    float resourceId;
    float frameNumber;
    bool valid;
    bool reset;
};

// Initialize history buffer
HistoryBuffer rendererHistoryInit(float resourceId) {
    HistoryBuffer h;
    h.resourceId = resourceId;
    h.frameNumber = 0.0;
    h.valid = false;
    h.reset = true;
    return h;
}

// Update history buffer state
void rendererHistoryUpdate(inout HistoryBuffer h, float currentFrame, bool cameraCut) {
    h.frameNumber = currentFrame;
    if (cameraCut) {
        h.reset = true;
        h.valid = false;
    } else {
        h.reset = false;
        h.valid = true;
    }
}

#endif
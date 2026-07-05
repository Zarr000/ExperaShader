#version 150
#ifndef RENDERER_HISTORY_GLSL
#define RENDERER_HISTORY_GLSL

#include "renderer_common.glsl"

// History buffer management with resource lifetime tracking

struct HistoryBuffer {
    float resourceId;
    float frameNumber;
    float lifetime;
    bool valid;
    bool reset;
    float producerNode;
    float consumerNode;
};

// Initialize history buffer
HistoryBuffer rendererHistoryInit(float resourceId, float producer, float consumer) {
    HistoryBuffer h;
    h.resourceId = resourceId;
    h.frameNumber = 0.0;
    h.lifetime = RESOURCE_STATE_CREATED;
    h.valid = false;
    h.reset = true;
    h.producerNode = producer;
    h.consumerNode = consumer;
    return h;
}

// Update history buffer state
void rendererHistoryUpdate(inout HistoryBuffer h, float currentFrame, bool cameraCut, float lifetime) {
    h.frameNumber = currentFrame;
    h.lifetime = lifetime;
    if (cameraCut) {
        h.reset = true;
        h.valid = false;
        h.lifetime = RESOURCE_STATE_CREATED;
    } else {
        h.reset = false;
        h.valid = true;
    }
}

// Mark history as read
void rendererHistoryRead(inout HistoryBuffer h) {
    h.lifetime = RESOURCE_STATE_READ;
}

// Mark history as written
void rendererHistoryWrite(inout HistoryBuffer h) {
    h.lifetime = RESOURCE_STATE_WRITTEN;
}

#endif
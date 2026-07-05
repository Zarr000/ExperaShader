#version 150
#ifndef RENDERER_FRAME_GLSL
#define RENDERER_FRAME_GLSL

#include "renderer_common.glsl"

// Frame management for render graph execution

struct FrameState {
    float frameNumber;
    float deltaTime;
    float time;
    bool cameraCut;
    bool firstFrame;
    bool fullReset;
};

// Initialize frame state
FrameState rendererFrameInit(float frameNumber, float time, float deltaTime) {
    FrameState f;
    f.frameNumber = frameNumber;
    f.deltaTime = deltaTime;
    f.time = time;
    f.cameraCut = (frameNumber < 2.0);
    f.firstFrame = (frameNumber < 1.0);
    f.fullReset = (frameNumber < 1.0);
    return f;
}

// Check if temporal effects should reset
bool rendererTemporalReset(FrameState f) {
    return f.cameraCut || f.firstFrame;
}

#endif
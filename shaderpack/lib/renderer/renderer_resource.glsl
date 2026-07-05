#version 150
#ifndef RENDERER_RESOURCE_GLSL
#define RENDERER_RESOURCE_GLSL

#include "renderer_common.glsl"

// Resource management for render graph

// Standard resource IDs
#define RESOURCE_ID_DEPTH             0.0
#define RESOURCE_ID_LINEAR_DEPTH      1.0
#define RESOURCE_ID_COLOR             2.0
#define RESOURCE_ID_NORMAL            3.0
#define RESOURCE_ID_ROUGHNESS         4.0
#define RESOURCE_ID_AO                5.0
#define RESOURCE_ID_MOTION_VECTORS    6.0
#define RESOURCE_ID_SSR               7.0
#define RESOURCE_ID_SSGI              8.0
#define RESOURCE_ID_SHADOW            9.0
#define RESOURCE_ID_CLOUD            10.0
#define RESOURCE_ID_WEATHER          11.0
#define RESOURCE_ID_WATER            12.0
#define RESOURCE_ID_HISTORY_TAA      13.0
#define RESOURCE_ID_HISTORY_SSR      14.0
#define RESOURCE_ID_HISTORY_SSGI     15.0
#define RESOURCE_ID_HISTORY_CLOUD    16.0

// Register a standard resource
void rendererRegisterStandardResources(inout RenderGraph g) {
    g.resourceCount = 0.0;

    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_DEPTH, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_LINEAR_DEPTH, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_COLOR, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_NORMAL, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_ROUGHNESS, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_AO, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_MOTION_VECTORS, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_SSR, screenSize.x, screenSize.y, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_SSGI, screenSize.x, screenSize.y, 0.0, 1.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_SHADOW, 1024.0, 1024.0, 0.0, 1.0, true, false));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_CLOUD, screenSize.x, screenSize.y, 0.0, 1.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_WEATHER, screenSize.x, screenSize.y, 0.0, 1.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_WATER, screenSize.x, screenSize.y, 0.0, 1.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_TAA, screenSize.x, screenSize.y, 0.0, 2.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_SSR, screenSize.x, screenSize.y, 0.0, 2.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_SSGI, screenSize.x, screenSize.y, 0.0, 2.0, true, true));
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_CLOUD, screenSize.x, screenSize.y, 0.0, 2.0, true, true));
}

#endif
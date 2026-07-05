#version 150
#ifndef RENDERER_RESOURCE_GLSL
#define RENDERER_RESOURCE_GLSL

#include "renderer_common.glsl"

// Resource management with lifetime tracking

// Resource lifetime states
#define RESOURCE_STATE_CREATED   0.0
#define RESOURCE_STATE_READ      1.0
#define RESOURCE_STATE_WRITTEN   2.0
#define RESOURCE_STATE_RELEASED  3.0

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

// Register a standard resource with default lifetime
void rendererRegisterStandardResources(inout RenderGraph g) {
    g.resourceCount = 0.0;

    // Geometry outputs
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_COLOR, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, false, 0.0, 3.0));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_NORMAL, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, false, 0.0, 2.0));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_DEPTH, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, false, 0.0, 2.0));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_ROUGHNESS, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, false, 2.0, 1.0));

    // Shadow
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_SHADOW, 1024.0, 1024.0, 0.0, 1.0, 3.0, true, false, 1.0, 5.0));

    // Atmosphere
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_TAA, screenSize.x, screenSize.y, 0.0, 2.0, 3.0, true, true, 3.0, 1.0));

    // Clouds
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_CLOUD, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, true, 4.0, 2.0));
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_CLOUD, screenSize.x, screenSize.y, 0.0, 2.0, 3.0, true, true, 4.0, 1.0));

    // Weather
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_WEATHER, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, true, 5.0, 2.0));

    // Water
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_WATER, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, true, 6.0, 1.0));

    // Deferred outputs
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_AO, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, false, 2.0, 1.0));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_SSR, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, false, 6.0, 1.0));
    rendererAddResource(g, RenderResource(RESOURCE_TEXTURE_2D, RESOURCE_ID_SSGI, screenSize.x, screenSize.y, 0.0, 1.0, 2.0, true, true, 7.0, 1.0));
    rendererAddResource(g, RenderResource(RESOURCE_HISTORY, RESOURCE_ID_HISTORY_SSGI, screenSize.x, screenSize.y, 0.0, 2.0, 3.0, true, true, 7.0, 1.0));
}

// Update resource lifetime
void rendererUpdateResourceLifetime(inout RenderGraph g, float resourceId, float state) {
    float idx = rendererFindResource(g, resourceId);
    if (idx >= 0.0) {
        g.resources[int(idx)].lifetime = state;
    }
}

#endif
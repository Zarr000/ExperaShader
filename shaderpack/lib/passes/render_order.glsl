#version 150

#ifndef PASSES_RENDER_ORDER_GLSL
#define PASSES_RENDER_ORDER_GLSL

// Architecture note: the renderer is organized into a logical pipeline order.
// 1. Geometry / GBuffer
// 2. Lighting / AO / GI
// 3. Reflections / Atmosphere / Clouds / Fog
// 4. Bloom / Tone Mapping / Camera / Final

#endif

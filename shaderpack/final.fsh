#version 150

// Final output shader with Renderer Core V2 integration

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/tonemap.glsl"
#include "lib/renderer/renderer_util.glsl"
#include "lib/renderer/renderer_resource.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;

// Renderer Core state
RendererState gRenderer;

void main() {
    // Initialize on first fragment
    if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
        gRenderer = rendererInit(frameTimeCounter, 0.016, frameTimeCounter);
    }

    vec3 color = texture2D(gColor, vUV).rgb;

    // Update resource lifetime
    rendererUpdateResourceLifetime(gRenderer.graph, RESOURCE_ID_COLOR, RESOURCE_STATE_READ);

    // Final tone mapping
    vec3 mapped = acesFilmic(color);
    vec3 srgb = linearToSRGB(mapped);

    FragColor = vec4(srgb, 1.0);
}
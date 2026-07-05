#version 150
#ifndef WATER_CAUSTICS_GLSL
#define WATER_CAUSTICS_GLSL

#include "water_common.glsl"
#include "../common/noise.glsl"

// Projected caustics
// Depth fade, shore fade, underwater projection

// Caustic pattern
float waterCausticPattern(vec2 pos, float time) {
    float c = 0.0;
    c += sin(pos.x * 3.0 + time) * sin(pos.y * 3.0 + time * 0.7);
    c += sin(pos.x * 7.0 - time * 1.3) * sin(pos.y * 5.0 + time * 0.5);
    c += sin((pos.x + pos.y) * 11.0 + time * 2.0);
    return c / 3.0;
}

// Caustic intensity at position
float waterCaustics(vec2 pos, float depth, float shoreDist, float strength, float time) {
    if (strength < 0.01) return 0.0;

    float pattern = waterCausticPattern(pos * 0.5, time * 0.3);
    pattern = saturate(pattern * 0.5 + 0.5);

    // Depth fade
    float depthFade = exp(-max(depth - 1.0, 0.0) * 0.2);

    // Shore fade
    float shoreFade = saturate(shoreDist / 2.0);

    return pattern * strength * depthFade * shoreFade;
}

#endif
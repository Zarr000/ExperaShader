#version 150
#ifndef SCREEN_SPACE_GLSL
#define SCREEN_SPACE_GLSL

// Screen-space helpers (original, minimal).

uniform vec2 screenSize;

vec2 getUVFromFragCoord(vec2 fragCoord) {
    return fragCoord / max(screenSize, vec2(1.0));
}

#endif


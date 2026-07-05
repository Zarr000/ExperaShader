#version 150
#ifndef SCREEN_SPACE_GLSL
#define SCREEN_SPACE_GLSL

#include "common/uniforms.glsl"

vec2 getUVFromFragCoord(vec2 fragCoord) {
    return fragCoord / max(screenSize, vec2(1.0));
}

#endif


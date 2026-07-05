#version 150

// Placeholder shadow map vertex shader for future cascades.

#include "lib/uniforms.glsl"

in vec3 Position;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

void main() {
    gl_Position = shadowProjection * shadowModelView * vec4(Position, 1.0);
}


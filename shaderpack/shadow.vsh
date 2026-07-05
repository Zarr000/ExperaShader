#version 150

// Shadow map vertex shader.

#include "lib/uniforms.glsl"

in vec3 Position;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform float time;

void main() {
    gl_Position = shadowProjection * shadowModelView * vec4(Position, 1.0);
}

